import { spawn } from "node:child_process";

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, { stdio: "inherit" });
    proc.on("close", (code) => (code === 0 ? resolve() : reject(code)));
  });
}

(async () => {
  await run("pnpm", ["hardhat", "clean"]);

  const anvil = spawn("anvil", ["-b", "1", "--dump-state", "./cache/anvil_state.json", "--disable-code-size-limit"]);

  let ready = false;
  anvil.stdout.on("data", (data) => {
    const msg = data.toString();
    if (!ready && (msg.includes("Listening") || msg.includes("HTTP"))) {
      ready = true;
      const deploy = spawn(
        "pnpm",
        [
          "hardhat",
          "ignition",
          "deploy",
          "--deployment-id",
          "staging_anvil",
          "--network",
          "anvil",
          "./ignition/modules/Devenv.ts",
        ],
        { stdio: "inherit" },
      );

      deploy.on("close", () => {
        anvil.kill("SIGTERM");
        process.exit(0);
      });
    }
  });

  anvil.stderr.pipe(process.stderr);
})();
