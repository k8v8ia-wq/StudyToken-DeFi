const hre = require("hardhat");

async function main() {
  console.log("开始部署合约...");

  // 获取部署账户
  const [deployer] = await hre.ethers.getSigners();
  console.log("部署者地址:", deployer.address);

  try {
    // 部署 StudyToken
    console.log("正在部署 StudyToken...");
    const StudyToken = await hre.ethers.getContractFactory("StudyToken");
    const studyToken = await StudyToken.deploy();
    await studyToken.waitForDeployment();
    const studyTokenAddress = await studyToken.getAddress();
    console.log("StudyToken合约地址:", studyTokenAddress);

    // 部署 AchievementReward
    console.log("正在部署 AchievementReward...");
    const AchievementReward = await hre.ethers.getContractFactory("AchievementReward");
    const achievementReward = await AchievementReward.deploy(studyTokenAddress);
    await achievementReward.waitForDeployment();
    const achievementRewardAddress = await achievementReward.getAddress();
    console.log("AchievementReward合约地址:", achievementRewardAddress);

    console.log("\n=== 部署完成 ===");
    console.log("StudyToken:", studyTokenAddress);
    console.log("AchievementReward:", achievementRewardAddress);
    
  } catch (error) {
    console.error("部署出错:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("部署失败:", error);
    process.exit(1);
  });