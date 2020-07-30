{ stdenv
, busybox
, dockerTools
, e2fsprogs
, git
, lib
, writeScriptBin
, xfsprogs
, mayastor
, mayastor-dev
, mayastor-adhoc
}:
let
  version_drv = import ../../lib/version.nix { inherit lib stdenv git; };
  version = builtins.readFile "${version_drv}";
  env = stdenv.lib.makeBinPath [ busybox xfsprogs e2fsprogs ];

  # common props for all mayastor images
  mayastor_image_props = {
    tag = version;
    created = "now";
    config = {
      Env = [ "PATH=${env}" ];
      ExposedPorts = { "10124/tcp" = { }; };
      Entrypoint = [ "/bin/mayastor" ];
    };
    # This directory is for mayastor jsonrpc socket file
    extraCommands = "mkdir -p var/tmp";
  };
  mayastor_csi_image_props = {
    tag = version;
    created = "now";
    config = {
      Entrypoint = [ "/bin/mayastor-csi" ];
      Env = [ "PATH=${env}" ];
    };
  };
in
rec {
  mayastor-image = dockerTools.buildImage (mayastor_image_props // {
    name = "mayadata/mayastor";
    contents = [ busybox mayastor ];
  });

  mayastor-dev-image = dockerTools.buildImage (mayastor_image_props // {
    name = "mayadata/mayastor-dev";
    contents = [ busybox mayastor-dev ];
  });

  mayastor-adhoc-image = dockerTools.buildImage (mayastor_image_props // {
    name = "mayadata/mayastor-adhoc";
    contents = [ busybox mayastor-adhoc ];
  });

  mayastorIscsiadm = writeScriptBin "mayastor-iscsiadm" ''
    #!${stdenv.shell}
    chroot /host /usr/bin/env -i PATH="/sbin:/bin:/usr/bin" iscsiadm "$@"
  '';

  mayastor-csi-image = dockerTools.buildLayeredImage (mayastor_csi_image_props // {
    name = "mayadata/mayastor-csi";
    contents = [ busybox mayastor mayastorIscsiadm ];
  });

  mayastor-csi-dev-image = dockerTools.buildImage (mayastor_csi_image_props // {
    name = "mayadata/mayastor-csi-dev";
    contents = [ busybox mayastor-dev mayastorIscsiadm ];
  });
}
