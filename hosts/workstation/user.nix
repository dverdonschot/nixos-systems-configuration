{ lib, config, pkgs, ... }:

{
  options = {
    main-user.enable
      = lib.mkEnableOption "enable user module";

    main-user.userName = lib.mkOption {
      default = "myuser";
      description = ''
        username
      '';
    };
  };
  
  config = lib.mkIf config.main-user.enable {
    users.users.${config.main-user.userName} = {
      isNormalUser = true;
      description = "main user";
      shell = pkgs.bash;
    };
  };
}
