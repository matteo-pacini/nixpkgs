import ./make-test-python.nix ({ pkgs, ... }:

let
  hello-world = pkgs.writeText "hello-world" ''
    {-# OPTIONS --guardedness #-}
    open import IO
    open import Level

    main = run {0ℓ} (putStrLn "Hello World!")
  '';
in
{
  name = "agda";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ alexarice turion ];
  };

  machine = { pkgs, ... }: {
    environment.systemPackages = [
      (pkgs.agda.withPackages {
        pkgs = p: [ p.standard-library ];
      })
    ];
    virtualisation.memorySize = 2000; # Agda uses a lot of memory
  };

  testScript = ''
    assert (
        "${pkgs.agdaPackages.lib.interfaceFile "Everything.agda"}" == "Everything.agdai"
    ), "wrong interface file for Everything.agda"
    assert (
        "${pkgs.agdaPackages.lib.interfaceFile "tmp/Everything.agda.md"}" == "tmp/Everything.agdai"
    ), "wrong interface file for tmp/Everything.agda.md"

    # Minimal script that typechecks
    machine.succeed("touch TestEmpty.agda")
    machine.succeed("agda TestEmpty.agda")

    # Hello world
    machine.succeed(
        "cp ${hello-world} HelloWorld.agda"
    )
    machine.succeed("agda -l standard-library -i . -c HelloWorld.agda")
    # Check execution
    assert "Hello World!" in machine.succeed(
        "./HelloWorld"
    ), "HelloWorld does not run properly"
  '';
}
)
