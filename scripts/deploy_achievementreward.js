// 部署 AchievementReward 合约的示例脚本
// 需要 Hardhat 环境：@nomicfoundation/hardhat-toolbox 或 ethers/hardhat

const hre = require("hardhat");

async function main() {
  console.log("开始部署 AchievementReward 合约...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("部署者地址:", deployer.address);
  console.log("账户余额:", hre.ethers.utils.formatEther(await deployer.getBalance()));

  const studyTokenAddress = process.env.STUDYTOKEN_ADDRESS || "<PUT_STUDYTOKEN_ADDRESS>";
  if (!hre.ethers.utils.isAddress(studyTokenAddress) || studyTokenAddress.includes("PUT")) {
    throw new Error("请通过环境变量 STUDYTOKEN_ADDRESS 提供有效的 StudyToken 地址");
  }

  const AchievementReward = await hre.ethers.getContractFactory("AchievementReward");
  const achievementReward = await AchievementReward.deploy(studyTokenAddress);
  await achievementReward.deployed();

  console.log("AchievementReward 合约地址:", achievementReward.address);
  console.log("useMint:", await achievementReward.useMint());
  console.log("mintLimit:", (await achievementReward.mintLimit()).toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("部署失败:", error);
    process.exit(1);
  });