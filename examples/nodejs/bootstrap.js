const { sdk } = require("./instrumentation");

async function main() {
  await sdk.start();
  require("./app");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
