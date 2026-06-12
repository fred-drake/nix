####################################
# Auto-generated -- do not modify! #
####################################
_: {
  "docker.gitea.com" = {
    "act_runner" = {
      "latest" = {
        "linux/amd64" = "docker.gitea.com/act_runner@sha256:3ec487309b4a97a31cd127a67689eb05eceb6ec1fa70aa902f7e9997f8c67e3a";
      };
    };
    "gitea" = {
      "1-rootless" = {
        "linux/amd64" = "docker.gitea.com/gitea@sha256:592a005e54327ed4969101ba60cf89dca569001ee71492ea0a6c43ce8de29379";
      };
    };
  };
  "docker.io" = {
    "amruthpillai/reactive-resume" = {
      "latest" = {
        "linux/amd64" = "docker.io/amruthpillai/reactive-resume@sha256:f3860b1fe93e2d77e27687995cb0b6343a7352e64dbd3c946e0ec2dc151f80c9";
      };
    };
    "apache/tika" = {
      "latest" = {
        "linux/amd64" = "docker.io/apache/tika@sha256:c9e60f15c1ff3f826e3102e18352ef21cf398a3f2505871913c3dc643dcc50ea";
      };
    };
    "clickhouse/clickhouse-server" = {
      "24.8-alpine" = {
        "linux/amd64" = "docker.io/clickhouse/clickhouse-server@sha256:0aed39f1983c18b4d20c9f2a19dff772e97bab13bc00b8639570950f2c4bfef3";
      };
    };
    "clusterzx/paperless-ai" = {
      "latest" = {
        "linux/amd64" = "docker.io/clusterzx/paperless-ai@sha256:19baad5ab2607d65087712fcb3ff74b6c5f7e840ea31061dace4d8ab1ef40a17";
      };
    };
    "filebrowser/filebrowser" = {
      "latest" = {
        "linux/amd64" = "docker.io/filebrowser/filebrowser@sha256:a2e4869ffc6b2adddc5797ce277ac3bd237f34201d079fee6bff6420ed28f40e";
      };
    };
    "gotenberg/gotenberg" = {
      "latest" = {
        "linux/amd64" = "docker.io/gotenberg/gotenberg@sha256:548fcf3e00ded485d0b85d2009154e9ef5ba81fcfe64a5fce9cab8a532e8e1bd";
      };
    };
    "library/redis" = {
      "latest" = {
        "linux/amd64" = "docker.io/library/redis@sha256:a505f8b9d8ac3ff7b0848055b4abf1901d6d77606774aa1e38bd37f1197ed2b5";
      };
    };
    "postgres" = {
      "16-alpine" = {
        "linux/amd64" = "docker.io/postgres@sha256:79950da386bda7fcc9d57aa9aa9be6c6d7407596a9b8f68014b09a778a9ab316";
      };
      "17" = {
        "linux/amd64" = "docker.io/postgres@sha256:0e91a106a4da991ecd9b2a511eb9a62cc106293a517deed33856ceda5ad429d7";
      };
      "18" = {
        "linux/amd64" = "docker.io/postgres@sha256:c27c01f74af25bde5f4f0f69d01944c4fc7f0376ea53c72aa1180dd593ce1d52";
      };
    };
    "woodpeckerci/woodpecker-agent" = {
      "v3.13.0" = {
        "linux/amd64" = "docker.io/woodpeckerci/woodpecker-agent@sha256:92e1729d00334828ea6d0dc1762e55a0b93b72e01e8e2d4435fe2d91e4a30783";
      };
    };
    "woodpeckerci/woodpecker-server" = {
      "v3.13.0" = {
        "linux/amd64" = "docker.io/woodpeckerci/woodpecker-server@sha256:268f891dd63f2e86f912fc3fbdff0b26552a79c4290b4be66b7c04acbe81fbb9";
      };
    };
  };
  "ghcr.io" = {
    "browserless/chromium" = {
      "v2.18.0" = {
        "linux/amd64" = "ghcr.io/browserless/chromium@sha256:bc7b9b4ce328e07226fdedb1e1166b7d0420c1ae6e009f8d2946837c100bee0f";
      };
    };
    "fred-drake/gitea-check-service" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/fred-drake/gitea-check-service@sha256:316b4a5023dc1285ce7f4be6d4b67fd5f289dfe3f0bf36c549dc485b9522da2a";
      };
    };
    "linuxserver/bazarr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/bazarr@sha256:e7db4037cbf74782220c0b8f38357140267079348f636f88d075c7b622f8d80d";
      };
    };
    "linuxserver/calibre-web" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/calibre-web@sha256:4ee6d92a533d522619c43f1704e0303685e5d8eb0fe775c78db1625e1068e3ae";
      };
    };
    "linuxserver/jellyfin" = {
      "latest" = {
        # WORKAROUND(jellyfin): held back from the newer digest (sha256:95133c6c...) during the
        # 2026-06-12 deploy. NOTE: the crash was NOT the image — this digest is also 10.11.10.
        # Root cause was a stale legacy /config/migrations.xml on ironforge whose entries were
        # all already in __EFMigrationsHistory, so CheckFirstTimeRunOrMigration's .Last() threw
        # "Sequence contains no elements". Fixed host-side by moving the file aside
        # (migrations.xml.pre-10.11-legacy.bak). Remove on the next container-update run; new
        # digests are safe to take now.
        "linux/amd64" = "ghcr.io/linuxserver/jellyfin@sha256:31e89a4ddb806fa0e17060f58cf5c64d324beb1755070f41ca65dc14613d83a1";
      };
    };
    "linuxserver/lidarr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/lidarr@sha256:f0565aa0f52e9e50d834011d01f2850fe380dbcc4aede77ee148d83addc93a84";
      };
    };
    "linuxserver/prowlarr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/prowlarr@sha256:9474bda8dd4176b2ef9a9b1278483e27c12a3ec600b393de99eede3e64dbbb3c";
      };
    };
    "linuxserver/radarr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/radarr@sha256:d4d5308d104f036d439cec74e15b9b2c6c344d7c6914a986d67c048721ea6c51";
      };
    };
    "linuxserver/sabnzbd" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/sabnzbd@sha256:daf7ad867517062e5f8487d58121ce22ccdbfb2ea3ea2df2b2f4dbc8ecc58c8c";
      };
    };
    "linuxserver/sonarr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/linuxserver/sonarr@sha256:1b7106a9fe8c2ac738260f09dfeec582bc17bcfe50632a1bfb5767b8d5f725a0";
      };
    };
    "paperless-ngx/paperless-ngx" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/paperless-ngx/paperless-ngx@sha256:835974fc3368fc6714aa38542db7a1f0f542d03244e39b981e519aefc100f355";
      };
    };
    "recyclarr/recyclarr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/recyclarr/recyclarr@sha256:bd0254f1bcc7c08947c5297b012c832bda58ebd39a366a6078ede7ef1969e3da";
      };
    };
    "seerr-team/seerr" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/seerr-team/seerr@sha256:2892b14e960d946fb91573792505dcba011075638f27104360fd21aa157fa2bc";
      };
    };
    "twin/gatus" = {
      "latest" = {
        "linux/amd64" = "ghcr.io/twin/gatus@sha256:f63f58d331521fb42f5c7a71a1ce9ba9d18fba19b2bc0c627d79ef1b981af384";
      };
    };
  };
  "gitea.internal.freddrake.com" = {
    "fdrake/traceway" = {
      "latest" = {
        "linux/amd64" = "gitea.internal.freddrake.com/fdrake/traceway@sha256:aaa5ecc261deeffc6f2256517e1641e3c89f181829021a0517012b8d8ea7f679";
      };
    };
  };
  "quay.io" = {
    "minio/minio" = {
      "latest" = {
        "linux/amd64" = "quay.io/minio/minio@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2";
      };
    };
  };
}
