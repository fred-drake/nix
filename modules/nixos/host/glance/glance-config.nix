{
  server = {
    port = 8080;
  };

  pages = [
    {
      name = "Home";
      columns = [
        {
          size = "small";
          widgets = [
            {
              type = "releases";
              show-source-icon = true;
              repositories = [
                "glanceapp/glance"
                "jellyfin/jellyfin"
                "sabnzbd/sabnzbd"
                "Sonarr/Sonarr"
                "Radarr/Radarr"
              ];
            }
            {
              type = "rss";
              limit = 10;
              collapse-after = 3;
              cache = "12h";
              feeds = [
                {
                  url = "https://selfh.st/rss/";
                  title = "selfh.st";
                  limit = 4;
                }
              ];
            }
          ];
        }
        {
          size = "full";
          widgets = [
            {
              type = "videos";
              channels = [
                "UCkVfrGwV-iG9bSsgCbrNPxQ" # Better Stack
                "UCuCkxoKLYO_EQ2GeFtbM_bw" # Half as Interesting
                "UCsWaVYzOFvEWDsEuvuZJ-8A" # EmergentMind
                "UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
                "UCsBjURrPoezykLs9EqgamOA" # Fireship
                "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
                "UCiT_r1GD7JSftnbViKHcOtQ" # Jeremy Chone
                "UCqAL_b-jUOTPjrTSNl2SNaQ" # Software Developer Diaries
                "UCHsSnExLE-YAhIz0-i3aWDw" # Action RPG
                "UCOk-gHyjcWZNj3Br4oxwh0A" # Techno Tim
                "UC_zBdZ0_H_jn41FDRG7q4Tw" # Vimjoyer
                "UCuGS5mN1_CpPzuOUAu2LluA" # Nixhero
                "UCVy16RS5eEDh8anP8j94G2A" # DB Tech
                "UCWI-ohtRu8eEeDj93hmUsUQ" # Coding With Lewis
                "UCg6gPGh8HU2U01vaFCAsvmQ" # Chris Titus Tech
                "UC1Zfv1Zrp1q5lKgBomzOyCA" # Melkey
                "UCo71RUe6DX4w-Vd47rFLXPg" # Typecraft
                "UCHaF9kM2wn8C3CLRwLkC2GQ" # Matt Williams
                "UCp3yVOm6A55nx65STpm3tXQ" # Craft Computing
                "UCcxQHI0pPuOQWLaTJJZoBIQ" # ReYOUniverse
                "UCWam55wUh-OOcvrGJisq0zA" # Seth Phaeno
                "UCwFpzG5MK5Shg_ncAhrgr9g" # Awesome Open Source
                "UCdngmbVKX1Tgre699-XLlUA" # TechWorld With Nana
                "UCS97tchJDq17Qms3cux8wcA" # chris@machine
                "UCxQKHvKbmSzGMvUrVtJYnUA" # Learn Linux TV
                "UCuCuEKq1xuRA0dFQj1qg9-Q" # Knowledgia
                "UCzumJvwc0KBrdq4jpvOR7RA" # Frontend Masters
                "UClq6aPav-cAmFwAqjAjAOWA" # Cloudy With Arnold
                "UCVVuMYbE98poTzS5Ohmz2DA" # Sidequest - Animated History
                "UCwcTeMUlBWbPcgRlFWMHn0g" # Green Tea Coding
                "UCGtVGfQUDGW_plNH7ITSMTQ" # The Dev Method
                "UCngN46PGiqmlUeyPbHKg5zg" # Nick Skriabin
                "UCwSmf8fUX-rZuBlYxb54ayw" # Gotta Know
                "UCGpEkSD7ATju4d_oA6-E1Uw" # Average Neovim Enjoyer
                "UCEEVcDuBRDiwxfXAgQjLGug" # Dreams of Autonomy
                "UCcN3IuIAR6Fn74FWMQf6lFA" # Science ABC
                "UCx3Vist13GWLzRPvhUxQ3Jg" # Andrew Courter
                "UCDiFRMQWpcp8_KD4vwIVicw" # Emergency Awesome
              ];
              playlists = [
              ];
            }
            {
              type = "group";
              widgets = [
                {
                  type = "reddit";
                  subreddit = "technology";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "selfhosted";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "ClaudeAI";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "NixOS";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "windsurf";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "fishshell";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "mcp";
                  show-thumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "PFSENSE";
                  show-thumbnails = true;
                }
              ];
            }
          ];
        }
        {
          size = "small";
          widgets = [
            {
              type = "weather";
              location = "\${GLANCE_ZIPCODE}";
              units = "imperial";
              hour-format = "12h";
            }
            {
              type = "twitch-channels";
              channels = [
                "aaronactionrpg"
                "theprimeagen"
                "j_blow"
                "piratesoftware"
                "cohhcarnage"
                "christitustech"
                "EJ_SA"
              ];
            }
          ];
        }
      ];
    }
  ];
}
