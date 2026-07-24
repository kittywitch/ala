{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    fl.url = "github:flakelib/std?ref=main";
    sona = {
      url = "github:lipu-linku/sona?ref=main";
      flake = false;
    };
    ijo = {
      url = "github:lipu-linku/ijo?ref=main";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, sona, ijo, fl }@inputs: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    inherit (pkgs) lib;
    Std = fl.lib;
    inherit (Std) Set List Tuple Str;
    licenseMap = with lib.licenses; {
      "OFL/GPL" = OR [ofl gpl3];
      # OFL
      "SIL Open Font License" = ofl;
      "SIL Open Font License, Version 1.1" = ofl;
      "OFL-1.1" = ofl;
      "OFL" = ofl;
      # CC0
      "CC0 1.0 Universal" = cc0;
      "CC0-1.0" = cc0;
      "CC0" = cc0;
      "CC0 / asked not to use" = cc0;
      # CC
      "CC BY 4.0" = cc-by-40;
      "CC BY-SA 3.0" = cc-by-sa-30;
      "CC BY-SA 4.0" = cc-by-sa-40;
      "CC BY-ND 4.0" = cc-by-nd-40;
      "Creative Commons BY-NC-SA 4.0" = cc-by-nc-sa-40;
      # other
      "MIT" = mit;
      "all rights reserved" = unfree;
    };
    fontData = Set.gen [
      "sitelen Antowi"
      "sitelen pan"
      "linja sike pi kute mute"
      "sitelen leko kiki"
      "sitelen sitelen (ss)"
      "linja pi pu lukin"
      "sitelen lili"
      "sitelenlili"
      "linja lape suwi"
      "Toki Pona Bubble"
      "sitelen pona pi lasin lukin"
      "sitelen pona pi palisa mute"
      "seta sans"
      "sitelen Komalin"
      "Interpixelia"
      "sitelen Nasi Masin"
      "linja lili"
      "Kaw Pixel"
      "sitelen telo"
      "Sitelen Pona"
      "Xim Sans Conlang"
      "sitelen pona tan pu"
      "nasin leko suwi lili"
      "sitelen Sans"
      "sitelen pona lili"
      "sitelen leko Teto"
      "i forgor"
      "TokiTengwar"
      "toki pona OTF"
      "YU SITELEN LEKO PONA"
      "AJN Sitelen Pona"
    ] (_: { broken = true; });

    fontMetadataDir = builtins.readDir "${inputs.sona.outPath}/fonts/metadata";
    fontMetadataFileReader = filename: builtins.readFile "${inputs.sona.outPath}/fonts/metadata/${filename}";
    fontDeriver = font: pkgs.stdenvNoCC.mkDerivation {
      pname = font.name;
      version = font.version;


      src = "${ijo}/nasinsitelen";

      installPhase = let

        isTtf = Str.hasSuffix "ttf" font.filename;
        isOtf = Str.hasSuffix "otf" font.filename;

      in ''
        runHook preInstall

        ${Str.optional isTtf ''
          mkdir -p $out/share/fonts/truetype
          install -Dm644 "${font.filename}" $out/share/fonts/truetype
        ''}
        ${Str.optional isOtf ''
          mkdir -p $out/share/fonts/opentype
          install -Dm644 "${font.filename}" $out/share/fonts/opentype
        ''}

        runHook postInstall
      '';

      meta = {
        inherit (font) author;
        broken = fontData.${font.name}.broken or false;
        license = licenseMap.${font.license} or lib.licenses.unfree;
      } // Set.optional (font.links ? "repo") {
          homepage = font.links.repo;
      } // Set.optional (font.links ? "webpage") {
          homepage = font.links.webpage;
        };
    };
    fontMetadataFiles = fontMetadataDir
      |> Set.keys
      |> List.map fontMetadataFileReader
      |> List.map fromTOML
      |> List.filter (f: f.filename != "");
    fontDerivations = fontMetadataFiles
      |> List.map (font: Tuple.tuple2 font.name (fontDeriver font))
      |> Set.fromList;
    allFonts = pkgs.linkFarmFromDrvs "all-fonts" (builtins.filter (f: !f.meta.broken) (builtins.attrValues fontDerivations));
  in {
    inherit lib pkgs inputs Std fontMetadataFiles fontDerivations allFonts;

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
