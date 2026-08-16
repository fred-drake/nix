#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "config.h"

extern char **environ;

/* Keep each string below Linux MAX_ARG_STRLEN and the complete environment
 * below Linux's 128 KiB ARG_MAX floor after transport/escape expansion. */
enum {
  TEAM_INSTRUCTIONS_MAX_BYTES = 65536,
  ENCODED_TEAM_INSTRUCTIONS_MAX_BYTES =
      ((TEAM_INSTRUCTIONS_MAX_BYTES + 2) / 3) * 4,
  ENVIRONMENT_NAME_MAX_BYTES = 128,
  ENVIRONMENT_VALUE_MAX_BYTES = 98304,
  /* Provider/helper persist at most 224 entries. The remaining 32 cover the
   * seven net launcher-owned entries plus systemd's execution environment. */
  ENVIRONMENT_ENTRY_MAX = 256,
  ENVIRONMENT_AGGREGATE_MAX_BYTES = 114688,
};

static const char *const unsafe_names[] = {
    "BASH_ENV",
    "ENV",
    "SHELLOPTS",
    "BASHOPTS",
    "BASH_XTRACEFD",
    "PS4",
    "PROMPT_COMMAND",
    "ZDOTDIR",
    "OPENSSL_CONF",
    "OPENSSL_MODULES",
    "OPENSSL_ENGINES",
    "GCONV_PATH",
    "LOCPATH",
    "NLSPATH",
    "HOME",
    "CODEX_HOME",
    "CODEX_CONFIG",
    "CODEX_MANAGED_PACKAGE_ROOT",
    "CODEX_SQLITE_HOME",
    "XDG_CONFIG_HOME",
    "XDG_CONFIG_DIRS",
    "XDG_DATA_HOME",
    "XDG_DATA_DIRS",
    "XDG_STATE_HOME",
    "XDG_CACHE_HOME",
    "BUZZ_ACP_EXIT_AFTER_INACTIVITY",
    "BUZZ_ACP_SUBSCRIBE",
    "BUZZ_ACP_NO_MENTION_FILTER",
    "BUZZ_ACP_KINDS",
    "BUZZ_ACP_CHANNELS",
    "BUZZ_ACP_CONFIG",
    "BUZZ_ACP_HEARTBEAT_INTERVAL",
    "BUZZ_ACP_HEARTBEAT_PROMPT",
    "BUZZ_ACP_HEARTBEAT_PROMPT_FILE",
    "BUZZ_AGENT_DISABLED_DIR",
    "BUZZ_AGENT_ENV_DIR",
    "BUZZ_AGENT_LOCK_FILE",
    "BUZZ_AGENT_OPERATION_LOCK_FILE",
    "BUZZ_AGENT_STATE_ROOT",
    "SERVICE_RESULT",
    "EXIT_CODE",
    "EXIT_STATUS",
};

static bool starts_with(const char *value, const char *prefix) {
  return strncmp(value, prefix, strlen(prefix)) == 0;
}

static bool unsafe_name(const char *name) {
  for (size_t i = 0; i < sizeof(unsafe_names) / sizeof(unsafe_names[0]); i++) {
    if (strcmp(name, unsafe_names[i]) == 0) {
      return true;
    }
  }
  return starts_with(name, "BASH_FUNC_") || starts_with(name, "LD_") ||
         starts_with(name, "DYLD_") || starts_with(name, "NODE_") ||
         starts_with(name, "BUN_") || starts_with(name, "NPM_") ||
         starts_with(name, "npm_") || starts_with(name, "DENO_");
}

static int sanitize_environment(void) {
  for (char **entry = environ; *entry != NULL;) {
    const char *separator = strchr(*entry, '=');
    if (separator == NULL) {
      entry++;
      continue;
    }
    size_t length = (size_t)(separator - *entry);
    char *name = strndup(*entry, length);
    if (name == NULL) {
      return -1;
    }
    bool unsafe = unsafe_name(name);
    if (unsafe && unsetenv(name) != 0) {
      free(name);
      return -1;
    }
    free(name);
    if (!unsafe) {
      entry++;
    }
  }
  return 0;
}

static bool environment_within_limits(void) {
  size_t count = 0;
  size_t aggregate = 0;
  for (char **entry = environ; *entry != NULL; entry++) {
    const char *separator = strchr(*entry, '=');
    if (separator == NULL) {
      return false;
    }
    size_t name_length = (size_t)(separator - *entry);
    size_t value_length = strlen(separator + 1);
    size_t entry_length = name_length + 1 + value_length + 1;
    if (++count > ENVIRONMENT_ENTRY_MAX ||
        name_length > ENVIRONMENT_NAME_MAX_BYTES ||
        value_length > ENVIRONMENT_VALUE_MAX_BYTES ||
        entry_length > ENVIRONMENT_AGGREGATE_MAX_BYTES - aggregate) {
      return false;
    }
    aggregate += entry_length;
  }
  return true;
}

static int base64_value(unsigned char value) {
  if (value >= 'A' && value <= 'Z') {
    return value - 'A';
  }
  if (value >= 'a' && value <= 'z') {
    return value - 'a' + 26;
  }
  if (value >= '0' && value <= '9') {
    return value - '0' + 52;
  }
  if (value == '+') {
    return 62;
  }
  if (value == '/') {
    return 63;
  }
  return -1;
}

static int decode_base64(const char *encoded, unsigned char **decoded,
                         size_t *decoded_length) {
  size_t length = strlen(encoded);
  if (length % 4 != 0) {
    return -1;
  }
  size_t capacity = length / 4 * 3;
  unsigned char *output = malloc(capacity + 1);
  if (output == NULL) {
    return -1;
  }
  size_t written = 0;
  for (size_t offset = 0; offset < length; offset += 4) {
    int first = base64_value((unsigned char)encoded[offset]);
    int second = base64_value((unsigned char)encoded[offset + 1]);
    bool third_padding = encoded[offset + 2] == '=';
    bool fourth_padding = encoded[offset + 3] == '=';
    int third =
        third_padding ? 0 : base64_value((unsigned char)encoded[offset + 2]);
    int fourth =
        fourth_padding ? 0 : base64_value((unsigned char)encoded[offset + 3]);
    bool last = offset + 4 == length;
    if (first < 0 || second < 0 || third < 0 || fourth < 0 ||
        (third_padding && !fourth_padding) ||
        ((third_padding || fourth_padding) && !last) ||
        (third_padding && (second & 0x0f) != 0) ||
        (fourth_padding && !third_padding && (third & 0x03) != 0)) {
      free(output);
      return -1;
    }
    output[written++] = (unsigned char)((first << 2) | (second >> 4));
    if (!third_padding) {
      output[written++] = (unsigned char)((second << 4) | (third >> 2));
    }
    if (!fourth_padding) {
      output[written++] = (unsigned char)((third << 6) | fourth);
    }
  }
  output[written] = '\0';
  *decoded = output;
  *decoded_length = written;
  return 0;
}

static bool continuation(unsigned char value) {
  return value >= 0x80 && value <= 0xbf;
}

static bool valid_utf8(const unsigned char *value, size_t length) {
  for (size_t i = 0; i < length;) {
    unsigned char first = value[i];
    if (first == 0) {
      return false;
    }
    if (first <= 0x7f) {
      i++;
    } else if (first >= 0xc2 && first <= 0xdf && i + 1 < length &&
               continuation(value[i + 1])) {
      i += 2;
    } else if (first == 0xe0 && i + 2 < length && value[i + 1] >= 0xa0 &&
               value[i + 1] <= 0xbf && continuation(value[i + 2])) {
      i += 3;
    } else if (((first >= 0xe1 && first <= 0xec) ||
                (first >= 0xee && first <= 0xef)) &&
               i + 2 < length && continuation(value[i + 1]) &&
               continuation(value[i + 2])) {
      i += 3;
    } else if (first == 0xed && i + 2 < length && value[i + 1] >= 0x80 &&
               value[i + 1] <= 0x9f && continuation(value[i + 2])) {
      i += 3;
    } else if (first == 0xf0 && i + 3 < length && value[i + 1] >= 0x90 &&
               value[i + 1] <= 0xbf && continuation(value[i + 2]) &&
               continuation(value[i + 3])) {
      i += 4;
    } else if (first >= 0xf1 && first <= 0xf3 && i + 3 < length &&
               continuation(value[i + 1]) && continuation(value[i + 2]) &&
               continuation(value[i + 3])) {
      i += 4;
    } else if (first == 0xf4 && i + 3 < length && value[i + 1] >= 0x80 &&
               value[i + 1] <= 0x8f && continuation(value[i + 2]) &&
               continuation(value[i + 3])) {
      i += 4;
    } else {
      return false;
    }
  }
  return true;
}

static char *read_contract(size_t *length) {
  FILE *file = fopen(CONTRACT_PATH, "rb");
  if (file == NULL || fseek(file, 0, SEEK_END) != 0) {
    if (file != NULL) {
      fclose(file);
    }
    return NULL;
  }
  long end = ftell(file);
  if (end <= 0 || end > 65536 || fseek(file, 0, SEEK_SET) != 0) {
    fclose(file);
    return NULL;
  }
  char *contents = malloc((size_t)end + 1);
  if (contents == NULL ||
      fread(contents, 1, (size_t)end, file) != (size_t)end) {
    free(contents);
    fclose(file);
    return NULL;
  }
  fclose(file);
  contents[end] = '\0';
  while (end > 0 && contents[end - 1] == '\n') {
    contents[--end] = '\0';
  }
  *length = (size_t)end;
  return contents;
}

static int set_fixed_environment(void) {
  return setenv("BUZZ_ACP_AGENT_COMMAND", AGENT_COMMAND, 1) == 0 &&
                 setenv("BUZZ_ACP_MCP_COMMAND", "", 1) == 0 &&
                 setenv("CODEX_PATH", CODEX_PATH, 1) == 0 &&
                 setenv("PATH", AGENT_PATH, 1) == 0 &&
                 setenv("HOME", SERVICE_HOME, 1) == 0 &&
                 setenv("CODEX_HOME", SERVICE_HOME "/.codex", 1) == 0 &&
                 setenv("BUZZ_ACP_SUBSCRIBE", "mentions", 1) == 0 &&
                 setenv("BUZZ_ACP_HEARTBEAT_INTERVAL", "0", 1) == 0
             ? 0
             : -1;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fputs("buzz-agent-run: missing harness command\n", stderr);
    return 64;
  }

  const char *encoded_environment =
      getenv("BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64");
  const char *raw_environment = getenv("BUZZ_ACP_TEAM_INSTRUCTIONS");
  char *encoded =
      encoded_environment == NULL ? NULL : strdup(encoded_environment);
  char *raw = raw_environment == NULL ? NULL : strdup(raw_environment);
  if ((encoded_environment != NULL && encoded == NULL) ||
      (raw_environment != NULL && raw == NULL) || sanitize_environment() != 0 ||
      set_fixed_environment() != 0) {
    fputs("buzz-agent-run: environment setup failed\n", stderr);
    free(encoded);
    free(raw);
    return 70;
  }

  unsigned char *decoded = NULL;
  size_t existing_length = 0;
  const char *existing = NULL;
  if ((encoded != NULL &&
       strlen(encoded) > ENCODED_TEAM_INSTRUCTIONS_MAX_BYTES) ||
      (encoded == NULL && raw != NULL &&
       strlen(raw) > TEAM_INSTRUCTIONS_MAX_BYTES)) {
    fputs("buzz-agent-run: team instructions too large\n", stderr);
    free(encoded);
    free(raw);
    return 65;
  }
  if (encoded != NULL) {
    if (decode_base64(encoded, &decoded, &existing_length) != 0 ||
        !valid_utf8(decoded, existing_length)) {
      fputs("buzz-agent-run: invalid encoded team instructions\n", stderr);
      free(encoded);
      free(raw);
      free(decoded);
      return 65;
    }
    if (existing_length > TEAM_INSTRUCTIONS_MAX_BYTES) {
      fputs("buzz-agent-run: team instructions too large\n", stderr);
      free(encoded);
      free(raw);
      free(decoded);
      return 65;
    }
    existing = (const char *)decoded;
  } else if (raw != NULL) {
    existing_length = strlen(raw);
    if (!valid_utf8((const unsigned char *)raw, existing_length)) {
      fputs("buzz-agent-run: invalid team instructions\n", stderr);
      free(raw);
      return 65;
    }
    existing = raw;
  }

  size_t contract_length = 0;
  char *contract = read_contract(&contract_length);
  size_t separator_length = existing_length > 0 ? 2 : 0;
  if (contract == NULL || existing_length > SIZE_MAX - separator_length ||
      existing_length + separator_length > SIZE_MAX - contract_length - 1) {
    fputs("buzz-agent-run: publication contract unavailable\n", stderr);
    free(encoded);
    free(raw);
    free(decoded);
    free(contract);
    return 70;
  }
  size_t composed_length = existing_length + separator_length + contract_length;
  char *composed = malloc(composed_length + 1);
  if (composed == NULL) {
    fputs("buzz-agent-run: environment setup failed\n", stderr);
    free(encoded);
    free(raw);
    free(decoded);
    free(contract);
    return 70;
  }
  size_t offset = 0;
  if (existing_length > 0) {
    memcpy(composed, existing, existing_length);
    offset += existing_length;
    memcpy(composed + offset, "\n\n", 2);
    offset += 2;
  }
  memcpy(composed + offset, contract, contract_length);
  composed[composed_length] = '\0';

  if (composed_length > ENVIRONMENT_VALUE_MAX_BYTES ||
      setenv("BUZZ_ACP_TEAM_INSTRUCTIONS", composed, 1) != 0 ||
      unsetenv("BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64") != 0) {
    fputs("buzz-agent-run: environment setup failed\n", stderr);
    free(encoded);
    free(raw);
    free(decoded);
    free(contract);
    free(composed);
    return 70;
  }

  free(encoded);
  free(raw);
  free(decoded);
  free(contract);
  free(composed);
  if (!environment_within_limits()) {
    fputs("buzz-agent-run: environment too large\n", stderr);
    return 65;
  }
  pid_t child = fork();
  if (child < 0) {
    fprintf(stderr, "buzz-agent-run: harness fork failed: %s\n",
            strerror(errno));
    return 70;
  }
  if (child == 0) {
    execv(argv[1], &argv[1]);
    fprintf(stderr, "buzz-agent-run: harness exec failed: %s\n",
            strerror(errno));
    _exit(70);
  }

  int status;
  while (waitpid(child, &status, 0) < 0) {
    if (errno != EINTR) {
      fprintf(stderr, "buzz-agent-run: harness wait failed: %s\n",
              strerror(errno));
      return 70;
    }
  }
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 128 + WTERMSIG(status);
  }
  return 70;
}
