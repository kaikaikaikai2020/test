-- MySQL dump 10.13  Distrib 5.7.15, for Win64 (x86_64)
--
-- Host: localhost    Database: yuqerdata
-- ------------------------------------------------------
-- Server version	5.7.15-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bond_debtpuredebtratio_wind`
--

DROP TABLE IF EXISTS `bond_debtpuredebtratio_wind`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bond_debtpuredebtratio_wind` (
  `tradingdate` text,
  `symbol` bigint(20) DEFAULT NULL,
  `symboltype` text,
  `shorname` text,
  `f_val` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bond_impliedvol_wind`
--

DROP TABLE IF EXISTS `bond_impliedvol_wind`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bond_impliedvol_wind` (
  `tradingdate` date DEFAULT NULL,
  `symbol` bigint(20) DEFAULT NULL,
  `symboltype` text,
  `shorname` text,
  `f_val` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bond_impliedvol_wind_update`
--

DROP TABLE IF EXISTS `bond_impliedvol_wind_update`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bond_impliedvol_wind_update` (
  `tradingdate` date NOT NULL,
  `symbol` varchar(12) NOT NULL,
  `symboltype` varchar(12) DEFAULT NULL,
  `f_val` float DEFAULT NULL,
  PRIMARY KEY (`symbol`,`tradingdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `convertiblebond_dayprice`
--

DROP TABLE IF EXISTS `convertiblebond_dayprice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `convertiblebond_dayprice` (
  `secID` varchar(12) DEFAULT NULL,
  `tickerBond` varchar(6) NOT NULL,
  `secShortNameBond` varchar(20) DEFAULT NULL,
  `tickerEqu` varchar(6) DEFAULT NULL,
  `secShortNameEqu` varchar(20) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `totalSize` float DEFAULT NULL,
  `remainSize` float DEFAULT NULL,
  `closePriceBond` float DEFAULT NULL,
  `convPrice` float DEFAULT NULL,
  `closePriceEqu` float DEFAULT NULL,
  `exerPar` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `chgPct7` float DEFAULT NULL,
  `bondPremRatio` float DEFAULT NULL,
  `debtPuredebtRatio` float DEFAULT NULL,
  `puredebtPremRatio` float DEFAULT NULL,
  PRIMARY KEY (`tickerBond`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `convertiblebond_info`
--

DROP TABLE IF EXISTS `convertiblebond_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `convertiblebond_info` (
  `bondID` bigint(20) DEFAULT NULL,
  `secID` text,
  `ticker` bigint(20) DEFAULT NULL,
  `secShortName` text,
  `exchangeCD` text,
  `secuCode` text,
  `prePlaceCode` double DEFAULT NULL,
  `prePlaceName` text,
  `onlinePlaceCode` double DEFAULT NULL,
  `onlinePlaceName` text,
  `prePlaceAmt` double DEFAULT NULL,
  `onlineIssueSize` double DEFAULT NULL,
  `onlinePlaceValidAmt` double DEFAULT NULL,
  `offlineIssueSize` double DEFAULT NULL,
  `leadunderSize` double DEFAULT NULL,
  `totalIssueCost` double DEFAULT NULL,
  `publicAnnounceDate` text,
  `resultDate` text,
  `listPublishDate` text,
  `prePlaceRecordDate` text,
  `prePlacePayStartdate` text,
  `prePlacePayEndtdate` text,
  `prePlacePre` double DEFAULT NULL,
  `prePlaceUnit` double DEFAULT NULL,
  `prePlaceValidAmt` double DEFAULT NULL,
  `prePlaceValidNum` double DEFAULT NULL,
  `prePlaceOversub` double DEFAULT NULL,
  `prePlaceSuccRatio` double DEFAULT NULL,
  `onlineIssueTime` text,
  `onlinePlaceUnit` double DEFAULT NULL,
  `onlinePlaceMax` double DEFAULT NULL,
  `onlinePlaceMin` double DEFAULT NULL,
  `onlinePlaceValidNum` double DEFAULT NULL,
  `onlinePlaceOversub` double DEFAULT NULL,
  `onlinePlaceSuccRate` double DEFAULT NULL,
  `offlinePlaceUnit` double DEFAULT NULL,
  `offlinePlaceMax` double DEFAULT NULL,
  `offlinePlaceMin` double DEFAULT NULL,
  `depositRatio` double DEFAULT NULL,
  `offlinePlaceValidAmt` double DEFAULT NULL,
  `offlinePlaceValidNum` double DEFAULT NULL,
  `offlinePlaceOversub` double DEFAULT NULL,
  `offlinePlaceSuccRatio` double DEFAULT NULL,
  `cpnFreqDes` text,
  `initialConvPrice` double DEFAULT NULL,
  `initialConvPriceDes` text,
  `redeemInt` double DEFAULT NULL,
  `redeemCoupon` double DEFAULT NULL,
  `redeemIntDes` text,
  `updateTime` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ecodataproget_s53`
--

DROP TABLE IF EXISTS `ecodataproget_s53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ecodataproget_s53` (
  `indicID` varchar(12) NOT NULL,
  `publishDate` datetime DEFAULT NULL,
  `periodDate` date NOT NULL,
  `dataValue` float DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL,
  PRIMARY KEY (`indicID`,`periodDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `equget`
--

DROP TABLE IF EXISTS `equget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `equget` (
  `ticker` text,
  `exchangeCD` text,
  `ListSectorCD` bigint(20) DEFAULT NULL,
  `ListSector` text,
  `secShortName` text,
  `listStatusCD` text,
  `listDate` text,
  `delistDate` text,
  `equTypeCD` text,
  `equType` text,
  `partyID` bigint(20) DEFAULT NULL,
  `totalShares` double DEFAULT NULL,
  `nonrestFloatShares` double DEFAULT NULL,
  `nonrestfloatA` double DEFAULT NULL,
  `endDate` text,
  `TShEquity` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `equinstsstateget_s53`
--

DROP TABLE IF EXISTS `equinstsstateget_s53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `equinstsstateget_s53` (
  `secID` varchar(12) DEFAULT NULL,
  `ticker` varchar(8) NOT NULL,
  `secShortName` varchar(15) DEFAULT NULL,
  `exchangeCD` varchar(6) DEFAULT NULL,
  `partyState` int(11) NOT NULL,
  `effDate` date NOT NULL,
  `reason` int(11) DEFAULT NULL,
  `updateTime` datetime NOT NULL,
  PRIMARY KEY (`ticker`,`effDate`,`partyState`,`updateTime`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `equrestructuringget`
--

DROP TABLE IF EXISTS `equrestructuringget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `equrestructuringget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(6) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(12) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `iniPublishDate` date DEFAULT NULL,
  `finPublishDate` date DEFAULT NULL,
  `program` float DEFAULT NULL,
  `isSucceed` float DEFAULT NULL,
  `restructuringType` float DEFAULT NULL,
  `underlyingType` float DEFAULT NULL,
  `underlyingVal` float DEFAULT NULL,
  `expenseVal` float DEFAULT NULL,
  `isRelevance` float DEFAULT NULL,
  `isMajorRes` float DEFAULT NULL,
  `payType` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `factor_wind_com_ttm`
--

DROP TABLE IF EXISTS `factor_wind_com_ttm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `factor_wind_com_ttm` (
  `factor_name` varchar(6) NOT NULL,
  `pub_date` date NOT NULL,
  `symbol` varchar(6) NOT NULL,
  `f_val` float DEFAULT NULL,
  PRIMARY KEY (`factor_name`,`pub_date`,`symbol`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fdmtisqgets53`
--

DROP TABLE IF EXISTS `fdmtisqgets53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fdmtisqgets53` (
  `secID` varchar(15) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `ticker` varchar(8) DEFAULT NULL,
  `secShortName` varchar(10) DEFAULT NULL,
  `exchangeCD` varchar(6) DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `tRevenue` float DEFAULT NULL,
  `revenue` float DEFAULT NULL,
  `intIncome` float DEFAULT NULL,
  `premEarned` float DEFAULT NULL,
  `commisIncome` float DEFAULT NULL,
  `TCogs` float DEFAULT NULL,
  `COGS` float DEFAULT NULL,
  `intExp` float DEFAULT NULL,
  `commisExp` float DEFAULT NULL,
  `premRefund` float DEFAULT NULL,
  `NCompensPayout` float DEFAULT NULL,
  `reserInsurContr` float DEFAULT NULL,
  `policyDivPayt` float DEFAULT NULL,
  `reinsurExp` float DEFAULT NULL,
  `bizTaxSurchg` float DEFAULT NULL,
  `sellExp` float DEFAULT NULL,
  `adminExp` float DEFAULT NULL,
  `finanExp` float DEFAULT NULL,
  `assetsImpairLoss` float DEFAULT NULL,
  `fValueChgGain` float DEFAULT NULL,
  `investIncome` float DEFAULT NULL,
  `AJInvestIncome` float DEFAULT NULL,
  `forexGain` float DEFAULT NULL,
  `assetsDispGain` float DEFAULT NULL,
  `othGain` float DEFAULT NULL,
  `operateProfit` float DEFAULT NULL,
  `NoperateIncome` float DEFAULT NULL,
  `NoperateExp` float DEFAULT NULL,
  `NCADisploss` float DEFAULT NULL,
  `TProfit` float DEFAULT NULL,
  `incomeTax` float DEFAULT NULL,
  `NIncome` float DEFAULT NULL,
  `goingConcernNI` float DEFAULT NULL,
  `quitConcernNI` float DEFAULT NULL,
  `NIncomeAttrP` float DEFAULT NULL,
  `minorityGain` float DEFAULT NULL,
  `othComprIncome` float DEFAULT NULL,
  `TComprIncome` float DEFAULT NULL,
  `comprIncAttrP` float DEFAULT NULL,
  `comprIncAttrMS` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fundetfconsget`
--

DROP TABLE IF EXISTS `fundetfconsget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fundetfconsget` (
  `index` bigint(20) DEFAULT NULL,
  `secID` text,
  `ticker` text,
  `secShortName` text,
  `exchangeCD` text,
  `tradeDate` text,
  `consID` text,
  `consTicker` text,
  `consName` text,
  `consExchangeCD` text,
  `quantity` double DEFAULT NULL,
  `cashSubsSign` double DEFAULT NULL,
  `CashRatio` double DEFAULT NULL,
  `fixedCahsAmount` double DEFAULT NULL,
  KEY `ix_FundETFConsGet_index` (`index`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fundget_s51`
--

DROP TABLE IF EXISTS `fundget_s51`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fundget_s51` (
  `secID` text,
  `ticker` text,
  `secShortName` text,
  `tradeAbbrName` text,
  `category` text,
  `operationMode` text,
  `indexFund` text,
  `etfLof` text,
  `isQdii` bigint(20) DEFAULT NULL,
  `isFof` bigint(20) DEFAULT NULL,
  `isGuarFund` bigint(20) DEFAULT NULL,
  `guarPeriod` double DEFAULT NULL,
  `guarRatio` double DEFAULT NULL,
  `exchangeCd` text,
  `listStatusCd` text,
  `managerName` text,
  `status` text,
  `establishDate` date DEFAULT NULL,
  `listDate` date DEFAULT NULL,
  `delistDate` date DEFAULT NULL,
  `expireDate` date DEFAULT NULL,
  `managementCompany` bigint(20) DEFAULT NULL,
  `managementFullName` text,
  `custodian` bigint(20) DEFAULT NULL,
  `custodianFullName` text,
  `perfBenchmark` text,
  `circulationShares` double DEFAULT NULL,
  `isClass` bigint(20) DEFAULT NULL,
  `idxID` text,
  `idxTicker` text,
  `idxShortName` text,
  `managementShortName` text,
  `custodianShortName` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fundholdingsget_s51`
--

DROP TABLE IF EXISTS `fundholdingsget_s51`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fundholdingsget_s51` (
  `secID` varchar(14) DEFAULT NULL,
  `ticker` varchar(14) DEFAULT NULL,
  `SecShortName` varchar(50) DEFAULT NULL,
  `reportDate` date DEFAULT NULL,
  `holdingsecType` varchar(14) DEFAULT NULL,
  `holdingSecID` varchar(14) DEFAULT NULL,
  `holdingTicker` varchar(14) DEFAULT NULL,
  `holdingExchangeCd` varchar(14) DEFAULT NULL,
  `holdingsecShortName` varchar(50) DEFAULT NULL,
  `holdVolume` float DEFAULT NULL,
  `marketValue` float DEFAULT NULL,
  `ratioInNa` float DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `currencyCd` varchar(14) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fundnavget_s51`
--

DROP TABLE IF EXISTS `fundnavget_s51`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fundnavget_s51` (
  `secID` varchar(14) DEFAULT NULL,
  `ticker` varchar(14) NOT NULL,
  `secShortName` varchar(50) DEFAULT NULL,
  `endDate` date NOT NULL,
  `NAV` float DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `ACCUM_NAV` float DEFAULT NULL,
  `currencyCd` varchar(14) DEFAULT NULL,
  `ADJUST_NAV` float DEFAULT NULL,
  `navChg` float DEFAULT NULL,
  `navChgPct` float DEFAULT NULL,
  `adjNavChgPct` float DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `partyShortName` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`ticker`,`endDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `future_return_1m`
--

DROP TABLE IF EXISTS `future_return_1m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `future_return_1m` (
  `symbol` varchar(6) NOT NULL,
  `tradingdate` date NOT NULL,
  `f_val` float DEFAULT NULL,
  PRIMARY KEY (`symbol`,`tradingdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `idxcloseweightget`
--

DROP TABLE IF EXISTS `idxcloseweightget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idxcloseweightget` (
  `ticker` varchar(10) NOT NULL,
  `tradingdate` date NOT NULL,
  `symbol` varchar(10) NOT NULL,
  `weight` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktcmefutdget_s50`
--

DROP TABLE IF EXISTS `mktcmefutdget_s50`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktcmefutdget_s50` (
  `ticker` varchar(14) NOT NULL,
  `tradeDate` date NOT NULL,
  `deliYear` int(11) DEFAULT NULL,
  `deliMonth` int(11) DEFAULT NULL,
  `contractObject` varchar(14) DEFAULT NULL,
  `preSettlePrice` float DEFAULT NULL,
  `preOpenInt` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `highestPriceSide` varchar(14) DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `lowestPriceSide` varchar(14) DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `closePriceSide` varchar(14) DEFAULT NULL,
  `settlePrice` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktequdadjafget`
--

DROP TABLE IF EXISTS `mktequdadjafget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktequdadjafget` (
  `ticker` varchar(10) NOT NULL,
  `tradeDate` date NOT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktequdadjafgetf0s53`
--

DROP TABLE IF EXISTS `mktequdadjafgetf0s53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktequdadjafgetf0s53` (
  `secID` varchar(12) DEFAULT NULL,
  `ticker` varchar(12) NOT NULL,
  `secShortName` varchar(12) DEFAULT NULL,
  `exchangeCD` varchar(12) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `preClosePrice` float DEFAULT NULL,
  `actPreClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `dealAmount` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  `negMarketValue` float DEFAULT NULL,
  `isOpen` int(11) DEFAULT NULL,
  `marketValue` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktequdadjafgetf1s53`
--

DROP TABLE IF EXISTS `mktequdadjafgetf1s53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktequdadjafgetf1s53` (
  `secID` varchar(12) DEFAULT NULL,
  `ticker` varchar(12) NOT NULL,
  `secShortName` varchar(12) DEFAULT NULL,
  `exchangeCD` varchar(12) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `preClosePrice` float DEFAULT NULL,
  `actPreClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `dealAmount` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  `negMarketValue` float DEFAULT NULL,
  `isOpen` int(11) DEFAULT NULL,
  `marketValue` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktequdget0s53`
--

DROP TABLE IF EXISTS `mktequdget0s53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktequdget0s53` (
  `symbol` varchar(6) NOT NULL,
  `tradeDate` date NOT NULL,
  `preClosePrice` float DEFAULT NULL,
  `actPreClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `dealAmount` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  `negMarketValue` float DEFAULT NULL,
  `marketValue` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `PE` float DEFAULT NULL,
  `PE1` float DEFAULT NULL,
  `PB` float DEFAULT NULL,
  PRIMARY KEY (`symbol`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktequmadjafget`
--

DROP TABLE IF EXISTS `mktequmadjafget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktequmadjafget` (
  `secID` text,
  `ticker` text,
  `secShortName` text,
  `exchangeCD` text,
  `monthBeginDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `tradeDays` bigint(20) DEFAULT NULL,
  `preClosePrice` double DEFAULT NULL,
  `openPrice` double DEFAULT NULL,
  `highestPrice` double DEFAULT NULL,
  `lowestPrice` double DEFAULT NULL,
  `closePrice` double DEFAULT NULL,
  `turnoverVol` bigint(20) DEFAULT NULL,
  `turnoverValue` double DEFAULT NULL,
  `chg` double DEFAULT NULL,
  `chgPct` double DEFAULT NULL,
  `return` double DEFAULT NULL,
  `turnoverRate` double DEFAULT NULL,
  `avgTurnoverRate` double DEFAULT NULL,
  `varReturn24` double DEFAULT NULL,
  `sdReturn24` double DEFAULT NULL,
  `avgReturn24` double DEFAULT NULL,
  `varReturn60` double DEFAULT NULL,
  `sdReturn60` double DEFAULT NULL,
  `avgReturn60` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktfunddget`
--

DROP TABLE IF EXISTS `mktfunddget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktfunddget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(8) NOT NULL,
  `exchangeCD` varchar(8) DEFAULT NULL,
  `secShortName` varchar(40) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `preClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `CHG` float DEFAULT NULL,
  `CHGPct` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `discount` float DEFAULT NULL,
  `discountRatio` float DEFAULT NULL,
  `circulationShares` float DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktiborget_s53`
--

DROP TABLE IF EXISTS `mktiborget_s53`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktiborget_s53` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(15) NOT NULL,
  `tradeDate` date NOT NULL,
  `currency` varchar(6) NOT NULL,
  `rate` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`currency`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mktmfutdget`
--

DROP TABLE IF EXISTS `mktmfutdget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mktmfutdget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `secShortNameEN` varchar(100) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `contractObject` varchar(8) DEFAULT NULL,
  `contractMark` varchar(8) DEFAULT NULL,
  `preSettlePrice` float DEFAULT NULL,
  `preClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `settlePrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `openInt` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  `chg1` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `mainCon` float DEFAULT NULL,
  `smainCon` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `national_bond_spyder`
--

DROP TABLE IF EXISTS `national_bond_spyder`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `national_bond_spyder` (
  `tradingdate` date NOT NULL,
  `date_month` varchar(12) NOT NULL,
  `date_v` varchar(12) DEFAULT NULL,
  `f_val` float DEFAULT NULL,
  PRIMARY KEY (`date_month`,`tradingdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newsheatindexnewgets55fz`
--

DROP TABLE IF EXISTS `newsheatindexnewgets55fz`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newsheatindexnewgets55fz` (
  `secID` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `exchangeName` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `newsEffectiveDate` date DEFAULT NULL,
  `heatIndex` float DEFAULT NULL,
  `newsCount` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newssentiindexgets55fz`
--

DROP TABLE IF EXISTS `newssentiindexgets55fz`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newssentiindexgets55fz` (
  `secID` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `exchangeName` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `newsEffectiveDate` date DEFAULT NULL,
  `sentimentIndex` float DEFAULT NULL,
  `newsCount` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nincome`
--

DROP TABLE IF EXISTS `nincome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nincome` (
  `secID` text,
  `publishdate` date DEFAULT NULL,
  `enddate` date DEFAULT NULL,
  `endDateRep` text,
  `partyID` bigint(20) DEFAULT NULL,
  `ticker` text,
  `secShortName` text,
  `exchangeCD` text,
  `actPubtime` datetime DEFAULT NULL,
  `mergedFlag` bigint(20) DEFAULT NULL,
  `reportType` text,
  `fiscalPeriod` bigint(20) DEFAULT NULL,
  `accoutingStandards` text,
  `currencyCD` text,
  `tRevenue` double DEFAULT NULL,
  `revenue` double DEFAULT NULL,
  `intIncome` double DEFAULT NULL,
  `intExp` double DEFAULT NULL,
  `premEarned` double DEFAULT NULL,
  `commisIncome` double DEFAULT NULL,
  `commisExp` double DEFAULT NULL,
  `TCogs` double DEFAULT NULL,
  `COGS` double DEFAULT NULL,
  `premRefund` double DEFAULT NULL,
  `NCompensPayout` double DEFAULT NULL,
  `reserInsurContr` double DEFAULT NULL,
  `policyDivPayt` double DEFAULT NULL,
  `reinsurExp` double DEFAULT NULL,
  `bizTaxSurchg` double DEFAULT NULL,
  `sellExp` double DEFAULT NULL,
  `adminExp` double DEFAULT NULL,
  `finanExp` double DEFAULT NULL,
  `assetsImpairLoss` double DEFAULT NULL,
  `fValueChgGain` double DEFAULT NULL,
  `investIncome` double DEFAULT NULL,
  `AJInvestIncome` double DEFAULT NULL,
  `forexGain` double DEFAULT NULL,
  `assetsDispGain` double DEFAULT NULL,
  `othGain` double DEFAULT NULL,
  `operateProfit` double DEFAULT NULL,
  `NoperateIncome` double DEFAULT NULL,
  `NoperateExp` double DEFAULT NULL,
  `NCADisploss` double DEFAULT NULL,
  `TProfit` double DEFAULT NULL,
  `incomeTax` double DEFAULT NULL,
  `NIncome` double DEFAULT NULL,
  `goingConcernNI` double DEFAULT NULL,
  `quitConcernNI` double DEFAULT NULL,
  `NIncomeAttrP` double DEFAULT NULL,
  `minorityGain` double DEFAULT NULL,
  `basicEPS` double DEFAULT NULL,
  `dilutedEPS` double DEFAULT NULL,
  `othComprIncome` double DEFAULT NULL,
  `TComprIncome` double DEFAULT NULL,
  `comprIncAttrP` double DEFAULT NULL,
  `comprIncAttrMS` double DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nincome_copy`
--

DROP TABLE IF EXISTS `nincome_copy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nincome_copy` (
  `secID` text,
  `publishdate` date DEFAULT NULL,
  `enddate` date DEFAULT NULL,
  `endDateRep` text,
  `partyID` bigint(20) DEFAULT NULL,
  `ticker` text,
  `secShortName` text,
  `exchangeCD` text,
  `actPubtime` datetime DEFAULT NULL,
  `mergedFlag` bigint(20) DEFAULT NULL,
  `reportType` text,
  `fiscalPeriod` bigint(20) DEFAULT NULL,
  `accoutingStandards` text,
  `currencyCD` text,
  `tRevenue` double DEFAULT NULL,
  `revenue` double DEFAULT NULL,
  `intIncome` double DEFAULT NULL,
  `intExp` double DEFAULT NULL,
  `premEarned` double DEFAULT NULL,
  `commisIncome` double DEFAULT NULL,
  `commisExp` double DEFAULT NULL,
  `TCogs` double DEFAULT NULL,
  `COGS` double DEFAULT NULL,
  `premRefund` double DEFAULT NULL,
  `NCompensPayout` double DEFAULT NULL,
  `reserInsurContr` double DEFAULT NULL,
  `policyDivPayt` double DEFAULT NULL,
  `reinsurExp` double DEFAULT NULL,
  `bizTaxSurchg` double DEFAULT NULL,
  `sellExp` double DEFAULT NULL,
  `adminExp` double DEFAULT NULL,
  `finanExp` double DEFAULT NULL,
  `assetsImpairLoss` double DEFAULT NULL,
  `fValueChgGain` double DEFAULT NULL,
  `investIncome` double DEFAULT NULL,
  `AJInvestIncome` double DEFAULT NULL,
  `forexGain` double DEFAULT NULL,
  `assetsDispGain` double DEFAULT NULL,
  `othGain` double DEFAULT NULL,
  `operateProfit` double DEFAULT NULL,
  `NoperateIncome` double DEFAULT NULL,
  `NoperateExp` double DEFAULT NULL,
  `NCADisploss` double DEFAULT NULL,
  `TProfit` double DEFAULT NULL,
  `incomeTax` double DEFAULT NULL,
  `NIncome` double DEFAULT NULL,
  `goingConcernNI` double DEFAULT NULL,
  `quitConcernNI` double DEFAULT NULL,
  `NIncomeAttrP` double DEFAULT NULL,
  `minorityGain` double DEFAULT NULL,
  `basicEPS` double DEFAULT NULL,
  `dilutedEPS` double DEFAULT NULL,
  `othComprIncome` double DEFAULT NULL,
  `TComprIncome` double DEFAULT NULL,
  `comprIncAttrP` double DEFAULT NULL,
  `comprIncAttrMS` double DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resconinduswget18`
--

DROP TABLE IF EXISTS `resconinduswget18`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resconinduswget18` (
  `secCode` varchar(20) DEFAULT NULL,
  `secName` varchar(20) DEFAULT NULL,
  `secType` int(11) DEFAULT NULL,
  `secTypeName` varchar(20) DEFAULT NULL,
  `repForeTime` datetime DEFAULT NULL,
  `foreYear` int(11) DEFAULT NULL,
  `foreType` int(11) DEFAULT NULL,
  `conEpsType` int(11) DEFAULT NULL,
  `conProfitType` int(11) DEFAULT NULL,
  `conEps` float DEFAULT NULL,
  `conProfit` float DEFAULT NULL,
  `conPe` float DEFAULT NULL,
  `conPeg` float DEFAULT NULL,
  `conRoe` float DEFAULT NULL,
  `conNa` float DEFAULT NULL,
  `conPb` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resconsecdataget18`
--

DROP TABLE IF EXISTS `resconsecdataget18`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resconsecdataget18` (
  `secCode` varchar(20) DEFAULT NULL,
  `secName` varchar(20) DEFAULT NULL,
  `secType` int(11) DEFAULT NULL,
  `repForeTime` datetime DEFAULT NULL,
  `ConEpsType` float DEFAULT NULL,
  `ConProfitType` float DEFAULT NULL,
  `foreYear` int(11) DEFAULT NULL,
  `foreType` int(11) DEFAULT NULL,
  `conEPS` float DEFAULT NULL,
  `conProfit` float DEFAULT NULL,
  `conPE` float DEFAULT NULL,
  `conROE` float DEFAULT NULL,
  `conNA` float DEFAULT NULL,
  `conPB` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resconsecderivativeget18`
--

DROP TABLE IF EXISTS `resconsecderivativeget18`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resconsecderivativeget18` (
  `secCode` varchar(20) DEFAULT NULL,
  `secName` varchar(20) DEFAULT NULL,
  `repForeTime` datetime DEFAULT NULL,
  `conIncomeRoll` float DEFAULT NULL,
  `conProfitRoll` float DEFAULT NULL,
  `conEpsRoll` float DEFAULT NULL,
  `conNaRoll` float DEFAULT NULL,
  `conPbRoll` float DEFAULT NULL,
  `conPsRoll` float DEFAULT NULL,
  `conPeRoll` float DEFAULT NULL,
  `conPegRoll` float DEFAULT NULL,
  `conRoeRoll` float DEFAULT NULL,
  `conProfitrate2yRoll` float DEFAULT NULL,
  `conIncomeYoyRoll` float DEFAULT NULL,
  `conProfitYoyRoll` float DEFAULT NULL,
  `epsRollMean13w` float DEFAULT NULL,
  `epsRollMean26w` float DEFAULT NULL,
  `epsRollMean52w` float DEFAULT NULL,
  `peRollMean13w` float DEFAULT NULL,
  `peRollMean26w` float DEFAULT NULL,
  `peRollMean52w` float DEFAULT NULL,
  `profitRollChg1w` float DEFAULT NULL,
  `profitRollChg4w` float DEFAULT NULL,
  `profitRollChg12w` float DEFAULT NULL,
  `profitRollChg26w` float DEFAULT NULL,
  `profitRollChg52w` float DEFAULT NULL,
  `orgCover10d` int(11) DEFAULT NULL,
  `orgCover25d` int(11) DEFAULT NULL,
  `orgCover75d` int(11) DEFAULT NULL,
  `profitRollStd5d` float DEFAULT NULL,
  `profitRollStd25d` float DEFAULT NULL,
  `profitRollStd75d` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resconsecincomegets18`
--

DROP TABLE IF EXISTS `resconsecincomegets18`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resconsecincomegets18` (
  `secCode` varchar(10) NOT NULL,
  `repForeTime` date NOT NULL,
  `foreYear` int(11) NOT NULL,
  `conIncomeType` int(11) NOT NULL,
  `conIncome` float DEFAULT NULL,
  PRIMARY KEY (`secCode`,`repForeTime`,`foreYear`,`conIncomeType`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rescontarpriscoreget18`
--

DROP TABLE IF EXISTS `rescontarpriscoreget18`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rescontarpriscoreget18` (
  `secCode` varchar(20) DEFAULT NULL,
  `secName` varchar(20) DEFAULT NULL,
  `repForeTime` datetime DEFAULT NULL,
  `conTarPrice` float DEFAULT NULL,
  `conTarPricType` int(11) DEFAULT NULL,
  `conScore` float DEFAULT NULL,
  `conScoreType` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `s24dividendyieldratio`
--

DROP TABLE IF EXISTS `s24dividendyieldratio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `s24dividendyieldratio` (
  `tradingdate` date NOT NULL,
  `f_val` float DEFAULT NULL,
  PRIMARY KEY (`tradingdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shibor_data`
--

DROP TABLE IF EXISTS `shibor_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shibor_data` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `tradeDate` date NOT NULL,
  `currency` varchar(20) NOT NULL,
  `rate` double DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`currency`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st_info`
--

DROP TABLE IF EXISTS `st_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `st_info` (
  `ticker` varchar(12) NOT NULL,
  `tradedate` date NOT NULL,
  `STflg` text,
  PRIMARY KEY (`ticker`,`tradedate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st_info_2`
--

DROP TABLE IF EXISTS `st_info_2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `st_info_2` (
  `tradingdate` date DEFAULT NULL,
  `secID` varchar(20) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `exchangeCD` varchar(30) DEFAULT NULL,
  `tradeAbbrName` varchar(30) DEFAULT NULL,
  `STflg` varchar(10) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_basic_info`
--

DROP TABLE IF EXISTS `stock_basic_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stock_basic_info` (
  `secID` text,
  `ticker` text,
  `exchangeCD` text,
  `ListSectorCD` bigint(20) DEFAULT NULL,
  `ListSector` text,
  `transCurrCD` text,
  `secShortName` text,
  `secFullName` text,
  `listStatusCD` text,
  `listDate` text,
  `delistDate` text,
  `equTypeCD` text,
  `equType` text,
  `exCountryCD` text,
  `partyID` bigint(20) DEFAULT NULL,
  `totalShares` double DEFAULT NULL,
  `nonrestFloatShares` double DEFAULT NULL,
  `nonrestfloatA` double DEFAULT NULL,
  `officeAddr` text,
  `primeOperating` text,
  `endDate` text,
  `TShEquity` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_basic_info_2`
--

DROP TABLE IF EXISTS `stock_basic_info_2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stock_basic_info_2` (
  `secID` text,
  `symbol` varchar(6) DEFAULT NULL,
  `exchangeCD` text,
  `ListSectorCD` bigint(20) DEFAULT NULL,
  `ListSector` text,
  `transCurrCD` text,
  `secShortName` text,
  `secFullName` text,
  `listStatusCD` text,
  `listDate` text,
  `delistDate` text,
  `equTypeCD` text,
  `equType` text,
  `exCountryCD` text,
  `partyID` bigint(20) DEFAULT NULL,
  `totalShares` double DEFAULT NULL,
  `nonrestFloatShares` double DEFAULT NULL,
  `nonrestfloatA` double DEFAULT NULL,
  `officeAddr` text,
  `primeOperating` text,
  `endDate` text,
  `TShEquity` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_accumadjfactor`
--

DROP TABLE IF EXISTS `yq_accumadjfactor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_accumadjfactor` (
  `ticker` varchar(6) DEFAULT NULL,
  `exDivDate` date DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_accumadjfactorv2`
--

DROP TABLE IF EXISTS `yq_accumadjfactorv2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_accumadjfactorv2` (
  `ticker` varchar(6) DEFAULT NULL,
  `exDivDate` date DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_dayprice`
--

DROP TABLE IF EXISTS `yq_dayprice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_dayprice` (
  `symbol` varchar(6) NOT NULL,
  `tradeDate` date NOT NULL,
  `preClosePrice` float DEFAULT NULL,
  `actPreClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `dealAmount` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  `negMarketValue` float DEFAULT NULL,
  `marketValue` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `PE` float DEFAULT NULL,
  `PE1` float DEFAULT NULL,
  `PB` float DEFAULT NULL,
  PRIMARY KEY (`symbol`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_factors_2t`
--

DROP TABLE IF EXISTS `yq_factors_2t`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_factors_2t` (
  `symbol` varchar(6) DEFAULT NULL,
  `tradeDate` date DEFAULT NULL,
  `EquityToAsset` float DEFAULT NULL,
  `BLEV` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_factors_9t`
--

DROP TABLE IF EXISTS `yq_factors_9t`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_factors_9t` (
  `symbol` varchar(6) NOT NULL,
  `tradeDate` date NOT NULL,
  `ETOP` float DEFAULT NULL,
  `PS` float DEFAULT NULL,
  `PCF` float DEFAULT NULL,
  `NetProfitGrowRate` float DEFAULT NULL,
  `ROE` float DEFAULT NULL,
  `ROA` float DEFAULT NULL,
  `GrossIncomeRatio` float DEFAULT NULL,
  `CashToCurrentLiability` float DEFAULT NULL,
  `CurrentRatio` float DEFAULT NULL,
  PRIMARY KEY (`symbol`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtbsget`
--

DROP TABLE IF EXISTS `yq_fdmtbsget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtbsget` (
  `secID` varchar(20) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `endDateRep` date DEFAULT NULL,
  `partyID` float DEFAULT NULL,
  `ticker` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `mergedFlag` float DEFAULT NULL,
  `reportType` varchar(20) DEFAULT NULL,
  `fiscalPeriod` float DEFAULT NULL,
  `accoutingStandards` varchar(20) DEFAULT NULL,
  `currencyCD` varchar(20) DEFAULT NULL,
  `cashCEquiv` float DEFAULT NULL,
  `settProv` float DEFAULT NULL,
  `loanToOthBankFi` float DEFAULT NULL,
  `tradingFA` float DEFAULT NULL,
  `NotesReceiv` float DEFAULT NULL,
  `AR` float DEFAULT NULL,
  `prepayment` float DEFAULT NULL,
  `premiumReceiv` float DEFAULT NULL,
  `reinsurReceiv` float DEFAULT NULL,
  `reinsurReserReceiv` float DEFAULT NULL,
  `intReceiv` float DEFAULT NULL,
  `divReceiv` float DEFAULT NULL,
  `othReceiv` float DEFAULT NULL,
  `purResaleFa` float DEFAULT NULL,
  `inventories` float DEFAULT NULL,
  `NCAWithin1Y` float DEFAULT NULL,
  `othCA` float DEFAULT NULL,
  `TCA` float DEFAULT NULL,
  `disburLA` float DEFAULT NULL,
  `availForSaleFa` float DEFAULT NULL,
  `htmInvest` float DEFAULT NULL,
  `LTReceive` float DEFAULT NULL,
  `LTEquityInvest` float DEFAULT NULL,
  `investRealEstate` float DEFAULT NULL,
  `fixedAssets` float DEFAULT NULL,
  `CIP` float DEFAULT NULL,
  `constMaterials` float DEFAULT NULL,
  `fixedAssetsDisp` float DEFAULT NULL,
  `producBiolAssets` float DEFAULT NULL,
  `oilAndGasAssets` float DEFAULT NULL,
  `intanAssets` float DEFAULT NULL,
  `RD` float DEFAULT NULL,
  `goodwill` float DEFAULT NULL,
  `LTAmorExp` float DEFAULT NULL,
  `deferTaxAssets` float DEFAULT NULL,
  `othNCA` float DEFAULT NULL,
  `TNCA` float DEFAULT NULL,
  `TAssets` float DEFAULT NULL,
  `STBorr` float DEFAULT NULL,
  `CBBorr` float DEFAULT NULL,
  `depos` float DEFAULT NULL,
  `loanFrOthBankFi` float DEFAULT NULL,
  `tradingFL` float DEFAULT NULL,
  `NotesPayable` float DEFAULT NULL,
  `AP` float DEFAULT NULL,
  `advanceReceipts` float DEFAULT NULL,
  `soldForRepurFa` float DEFAULT NULL,
  `commisPayable` float DEFAULT NULL,
  `payrollPayable` float DEFAULT NULL,
  `taxesPayable` float DEFAULT NULL,
  `intPayable` float DEFAULT NULL,
  `divPayable` float DEFAULT NULL,
  `othPayable` float DEFAULT NULL,
  `reinsurPayable` float DEFAULT NULL,
  `insurReser` float DEFAULT NULL,
  `fundsSecTradAgen` float DEFAULT NULL,
  `fundsSecUndwAgen` float DEFAULT NULL,
  `NCLWithin1Y` float DEFAULT NULL,
  `othCL` float DEFAULT NULL,
  `TCL` float DEFAULT NULL,
  `LTBorr` float DEFAULT NULL,
  `bondPayable` float DEFAULT NULL,
  `preferredStockL` float DEFAULT NULL,
  `perpetualBondL` float DEFAULT NULL,
  `LTPayable` float DEFAULT NULL,
  `specificPayables` float DEFAULT NULL,
  `estimatedLiab` float DEFAULT NULL,
  `deferTaxLiab` float DEFAULT NULL,
  `othNCL` float DEFAULT NULL,
  `TNCL` float DEFAULT NULL,
  `TLiab` float DEFAULT NULL,
  `paidInCapital` float DEFAULT NULL,
  `othEquityInstr` float DEFAULT NULL,
  `preferredStockE` float DEFAULT NULL,
  `perpetualBondE` float DEFAULT NULL,
  `capitalReser` float DEFAULT NULL,
  `treasuryShare` float DEFAULT NULL,
  `othCompreIncome` float DEFAULT NULL,
  `specialReser` float DEFAULT NULL,
  `surplusReser` float DEFAULT NULL,
  `ordinRiskReser` float DEFAULT NULL,
  `retainedEarnings` float DEFAULT NULL,
  `forexDiffer` float DEFAULT NULL,
  `TEquityAttrP` float DEFAULT NULL,
  `minorityInt` float DEFAULT NULL,
  `TShEquity` float DEFAULT NULL,
  `TLiabEquity` float DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtcfgetall`
--

DROP TABLE IF EXISTS `yq_fdmtcfgetall`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtcfgetall` (
  `secID` varchar(20) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `endDateRep` date DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `mergedFlag` int(11) DEFAULT NULL,
  `reportType` varchar(10) DEFAULT NULL,
  `fiscalPeriod` float DEFAULT NULL,
  `accoutingStandards` varchar(10) DEFAULT NULL,
  `currencyCD` varchar(10) DEFAULT NULL,
  `CFrSaleGS` float DEFAULT NULL,
  `NDeposIncrCFI` float DEFAULT NULL,
  `NIncrBorrFrCB` float DEFAULT NULL,
  `NIncBorrOthFI` float DEFAULT NULL,
  `premFrOrigContr` float DEFAULT NULL,
  `NReinsurPrem` float DEFAULT NULL,
  `NIncPhDeposInv` float DEFAULT NULL,
  `NIncDispTradFA` float DEFAULT NULL,
  `IFCCashIncr` float DEFAULT NULL,
  `NIncFrBorr` float DEFAULT NULL,
  `NCApIncrRepur` float DEFAULT NULL,
  `refundOfTax` float DEFAULT NULL,
  `CFrOthOperateA` float DEFAULT NULL,
  `CInfFrOperateA` float DEFAULT NULL,
  `CPaidGS` float DEFAULT NULL,
  `NIncDisburOfLA` float DEFAULT NULL,
  `NIncrDeposInFI` float DEFAULT NULL,
  `origContrCIndem` float DEFAULT NULL,
  `CPaidIFC` float DEFAULT NULL,
  `CPaidPolDiv` float DEFAULT NULL,
  `CPaidToForEmpl` float DEFAULT NULL,
  `CPaidForTaxes` float DEFAULT NULL,
  `CPaidForOthOpA` float DEFAULT NULL,
  `COutfOperateA` float DEFAULT NULL,
  `NCFOperateA` float DEFAULT NULL,
  `procSellInvest` float DEFAULT NULL,
  `gainInvest` float DEFAULT NULL,
  `dispFixAssetsOth` float DEFAULT NULL,
  `NDispSubsOthBizC` float DEFAULT NULL,
  `CFrOthInvestA` float DEFAULT NULL,
  `CInfFrInvestA` float DEFAULT NULL,
  `purFixAssetsOth` float DEFAULT NULL,
  `CPaidInvest` float DEFAULT NULL,
  `NIncrPledgeLoan` float DEFAULT NULL,
  `NCPaidAcquis` float DEFAULT NULL,
  `CPaidOthInvestA` float DEFAULT NULL,
  `COutfFrInvestA` float DEFAULT NULL,
  `NCFFrInvestA` float DEFAULT NULL,
  `CFrCapContr` float DEFAULT NULL,
  `CFrMinoSSubs` float DEFAULT NULL,
  `CFrBorr` float DEFAULT NULL,
  `CFrIssueBond` float DEFAULT NULL,
  `CFrOthFinanA` float DEFAULT NULL,
  `CInfFrFinanA` float DEFAULT NULL,
  `CPaidForDebts` float DEFAULT NULL,
  `CPaidDivProfInt` float DEFAULT NULL,
  `divProfSubsMinoS` float DEFAULT NULL,
  `CPaidOthFinanA` float DEFAULT NULL,
  `COutfFrFinanA` float DEFAULT NULL,
  `NCFFrFinanA` float DEFAULT NULL,
  `forexEffects` float DEFAULT NULL,
  `NChangeInCash` float DEFAULT NULL,
  `NCEBegBal` float DEFAULT NULL,
  `NCEEndBal` float DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtcfttmpitget`
--

DROP TABLE IF EXISTS `yq_fdmtcfttmpitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtcfttmpitget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` float DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `endDate` date NOT NULL,
  `publishDate` date NOT NULL,
  `isNew` float DEFAULT NULL,
  `isCalc` float DEFAULT NULL,
  `CFrSaleGS` float DEFAULT NULL,
  `NDeposIncrCFI` float DEFAULT NULL,
  `NIncrBorrFrCB` float DEFAULT NULL,
  `NIncBorrOthFI` float DEFAULT NULL,
  `premFrOrigContr` float DEFAULT NULL,
  `NReinsurPrem` float DEFAULT NULL,
  `NIncPhDeposInv` float DEFAULT NULL,
  `NIncDispTradFA` float DEFAULT NULL,
  `IFCCashIncr` float DEFAULT NULL,
  `NIncFrBorr` float DEFAULT NULL,
  `NCApIncrRepur` float DEFAULT NULL,
  `refundOfTax` float DEFAULT NULL,
  `CFrOthOperateA` float DEFAULT NULL,
  `CInfFrOperateA` float DEFAULT NULL,
  `CPaidGS` float DEFAULT NULL,
  `NIncDisburOfLA` float DEFAULT NULL,
  `NIncrDeposInFI` float DEFAULT NULL,
  `origContrCIndem` float DEFAULT NULL,
  `CPaidIFC` float DEFAULT NULL,
  `CPaidPolDiv` float DEFAULT NULL,
  `CPaidToForEmpl` float DEFAULT NULL,
  `CPaidForTaxes` float DEFAULT NULL,
  `CPaidForOthOpA` float DEFAULT NULL,
  `COutfOperateA` float DEFAULT NULL,
  `NCFOperateA` float DEFAULT NULL,
  `procSellInvest` float DEFAULT NULL,
  `gainInvest` float DEFAULT NULL,
  `dispFixAssetsOth` float DEFAULT NULL,
  `NDispSubsOthBizC` float DEFAULT NULL,
  `CFrOthInvestA` float DEFAULT NULL,
  `CInfFrInvestA` float DEFAULT NULL,
  `purFixAssetsOth` float DEFAULT NULL,
  `CPaidInvest` float DEFAULT NULL,
  `NIncrPledgeLoan` float DEFAULT NULL,
  `NCPaidAcquis` float DEFAULT NULL,
  `CPaidOthInvestA` float DEFAULT NULL,
  `COutfFrInvestA` float DEFAULT NULL,
  `NCFFrInvestA` float DEFAULT NULL,
  `CFrCapContr` float DEFAULT NULL,
  `CFrMinoSSubs` float DEFAULT NULL,
  `CFrBorr` float DEFAULT NULL,
  `CFrIssueBond` float DEFAULT NULL,
  `CFrOthFinanA` float DEFAULT NULL,
  `CInfFrFinanA` float DEFAULT NULL,
  `CPaidForDebts` float DEFAULT NULL,
  `CPaidDivProfInt` float DEFAULT NULL,
  `divProfSubsMinoS` float DEFAULT NULL,
  `CPaidOthFinanA` float DEFAULT NULL,
  `COutfFrFinanA` float DEFAULT NULL,
  `NCFFrFinanA` float DEFAULT NULL,
  `forexEffects` float DEFAULT NULL,
  `NChangeInCash` float DEFAULT NULL,
  `NCEBegBal` float DEFAULT NULL,
  `NCEEndBal` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`endDate`,`publishDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtderpitget`
--

DROP TABLE IF EXISTS `yq_fdmtderpitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtderpitget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `secShortName` varchar(10) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `tFixedAssets` float DEFAULT NULL,
  `intFreeCl` float DEFAULT NULL,
  `intFreeNcl` float DEFAULT NULL,
  `intCl` float DEFAULT NULL,
  `intDebt` float DEFAULT NULL,
  `nDebt` float DEFAULT NULL,
  `nTanAssets` float DEFAULT NULL,
  `workCapital` float DEFAULT NULL,
  `nWorkCapital` float DEFAULT NULL,
  `IC` float DEFAULT NULL,
  `tRe` float DEFAULT NULL,
  `grossProfit` float DEFAULT NULL,
  `opaProfit` float DEFAULT NULL,
  `valChgProfit` float DEFAULT NULL,
  `nIntExp` float DEFAULT NULL,
  `EBIT` float DEFAULT NULL,
  `EBITDA` float DEFAULT NULL,
  `EBIAT` float DEFAULT NULL,
  `nrProfitLoss` float DEFAULT NULL,
  `niAttrPCut` float DEFAULT NULL,
  `FCFF` float DEFAULT NULL,
  `FCFE` float DEFAULT NULL,
  `DA` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmteeget`
--

DROP TABLE IF EXISTS `yq_fdmteeget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmteeget` (
  `secID` varchar(20) DEFAULT NULL,
  `publishDate` datetime DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `partyID` float DEFAULT NULL,
  `ticker` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `mergedFlag` float DEFAULT NULL,
  `reportType` varchar(20) DEFAULT NULL,
  `fiscalPeriod` float DEFAULT NULL,
  `accoutingStandards` varchar(20) DEFAULT NULL,
  `currencyCD` varchar(20) DEFAULT NULL,
  `revenue` float DEFAULT NULL,
  `primeOperRev` float DEFAULT NULL,
  `grossProfit` float DEFAULT NULL,
  `operateProfit` float DEFAULT NULL,
  `TProfit` float DEFAULT NULL,
  `NIncomeAttrP` float DEFAULT NULL,
  `NIncomeCut` float DEFAULT NULL,
  `NCfOperA` float DEFAULT NULL,
  `basicEPS` float DEFAULT NULL,
  `EPSW` float DEFAULT NULL,
  `EPSCut` float DEFAULT NULL,
  `EPSCutW` float DEFAULT NULL,
  `ROE` float DEFAULT NULL,
  `ROEW` float DEFAULT NULL,
  `ROECut` float DEFAULT NULL,
  `ROECutW` float DEFAULT NULL,
  `NCfOperAPs` float DEFAULT NULL,
  `TAssets` float DEFAULT NULL,
  `TEquityAttrP` float DEFAULT NULL,
  `paidInCapital` float DEFAULT NULL,
  `NAssetPS` float DEFAULT NULL,
  `revenueLY` float DEFAULT NULL,
  `primeOperRevLY` float DEFAULT NULL,
  `grossProfitLY` float DEFAULT NULL,
  `operProfitLY` float DEFAULT NULL,
  `TProfitLY` float DEFAULT NULL,
  `NIncomeAttrPLY` float DEFAULT NULL,
  `NIncomeCutLY` float DEFAULT NULL,
  `NCfOperALY` float DEFAULT NULL,
  `basicEPSLY` float DEFAULT NULL,
  `EPSWLY` float DEFAULT NULL,
  `EPSCutLY` float DEFAULT NULL,
  `EPSCutWLY` float DEFAULT NULL,
  `ROELY` float DEFAULT NULL,
  `ROEWLY` float DEFAULT NULL,
  `ROECutLY` float DEFAULT NULL,
  `ROECutWLY` float DEFAULT NULL,
  `NCfOperAPsLY` float DEFAULT NULL,
  `TAssetsLY` float DEFAULT NULL,
  `TEquityAttrPLY` float DEFAULT NULL,
  `NAssetPsLY` float DEFAULT NULL,
  `revenueYOY` float DEFAULT NULL,
  `primeOperRevYOY` float DEFAULT NULL,
  `grossProfitYOY` float DEFAULT NULL,
  `operProfitYOY` float DEFAULT NULL,
  `TProfitYOY` float DEFAULT NULL,
  `NIncomeAttrPYOY` float DEFAULT NULL,
  `NIncomeCutYOY` float DEFAULT NULL,
  `NCFOperAYOY` float DEFAULT NULL,
  `basicEPSYOY` float DEFAULT NULL,
  `EPSWYOY` float DEFAULT NULL,
  `EPSCutYOY` float DEFAULT NULL,
  `EPSCutWYOY` float DEFAULT NULL,
  `ROEYOY` float DEFAULT NULL,
  `ROEWYOY` float DEFAULT NULL,
  `ROECutYOY` float DEFAULT NULL,
  `ROECutWYOY` float DEFAULT NULL,
  `NCfOperAPsYOY` float DEFAULT NULL,
  `TAssetsYOY` float DEFAULT NULL,
  `TEquityAttrPYOY` float DEFAULT NULL,
  `NAssetPsYOY` float DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtefget`
--

DROP TABLE IF EXISTS `yq_fdmtefget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtefget` (
  `secID` varchar(14) DEFAULT NULL,
  `publishDate` datetime DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `ticker` varchar(14) DEFAULT NULL,
  `secShortName` varchar(14) DEFAULT NULL,
  `exchangeCD` varchar(14) DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `mergedFlag` int(11) DEFAULT NULL,
  `reportType` varchar(14) DEFAULT NULL,
  `fiscalPeriod` int(11) DEFAULT NULL,
  `accoutingStandards` varchar(14) DEFAULT NULL,
  `currencyCD` varchar(14) DEFAULT NULL,
  `forecastType` int(11) DEFAULT NULL,
  `revChgrLL` float DEFAULT NULL,
  `revChgrUPL` float DEFAULT NULL,
  `expRevLL` float DEFAULT NULL,
  `expRevUPL` float DEFAULT NULL,
  `NIncomeChgrLL` float DEFAULT NULL,
  `NIncomeChgrUPL` float DEFAULT NULL,
  `expnIncomeLL` float DEFAULT NULL,
  `expnIncomeUPL` float DEFAULT NULL,
  `NIncAPChgrLL` float DEFAULT NULL,
  `NIncAPChgrUPL` float DEFAULT NULL,
  `expnIncAPLL` float DEFAULT NULL,
  `expnIncAPUPL` float DEFAULT NULL,
  `expEPSLL` float DEFAULT NULL,
  `expEPSUPL` float DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtindipspitget`
--

DROP TABLE IF EXISTS `yq_fdmtindipspitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtindipspitget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `EPS` float DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `basicEPS` float DEFAULT NULL,
  `dilutedEPS` float DEFAULT NULL,
  `nAssetPS` float DEFAULT NULL,
  `tRevPS` float DEFAULT NULL,
  `revPS` float DEFAULT NULL,
  `opPS` float DEFAULT NULL,
  `EBITPS` float DEFAULT NULL,
  `cReserPS` float DEFAULT NULL,
  `sReserPS` float DEFAULT NULL,
  `reserPS` float DEFAULT NULL,
  `rePS` float DEFAULT NULL,
  `tRePS` float DEFAULT NULL,
  `nCfOperAPS` float DEFAULT NULL,
  `nCInCashPS` float DEFAULT NULL,
  `FCFFPS` float DEFAULT NULL,
  `FCFEPS` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtindiqget`
--

DROP TABLE IF EXISTS `yq_fdmtindiqget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtindiqget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `EPS` float DEFAULT NULL,
  `grossMARgin` float DEFAULT NULL,
  `npMARgin` float DEFAULT NULL,
  `ROE` float DEFAULT NULL,
  `ROEA` float DEFAULT NULL,
  `ROECutA` float DEFAULT NULL,
  `ROA` float DEFAULT NULL,
  `periodExpTR` float DEFAULT NULL,
  `pCostExp` float DEFAULT NULL,
  `NITR` float DEFAULT NULL,
  `sellExpTR` float DEFAULT NULL,
  `adminExpTR` float DEFAULT NULL,
  `finanExpTR` float DEFAULT NULL,
  `ailTR` float DEFAULT NULL,
  `TCOGSTR` float DEFAULT NULL,
  `COGSTR` float DEFAULT NULL,
  `opTR` float DEFAULT NULL,
  `opaPTp` float DEFAULT NULL,
  `valChgPTp` float DEFAULT NULL,
  `NICutNI` float DEFAULT NULL,
  `faTurnover` float DEFAULT NULL,
  `caTurnover` float DEFAULT NULL,
  `taTurnover` float DEFAULT NULL,
  `invenTurnover` float DEFAULT NULL,
  `daysInven` float DEFAULT NULL,
  `ARTurnover` float DEFAULT NULL,
  `daysAR` float DEFAULT NULL,
  `operCycle` float DEFAULT NULL,
  `APTurnover` float DEFAULT NULL,
  `daysAP` float DEFAULT NULL,
  `CFsgsR` float DEFAULT NULL,
  `nCFOpaR` float DEFAULT NULL,
  `nCFOpaOpap` float DEFAULT NULL,
  `nCFOpaNIAttrP` float DEFAULT NULL,
  `tRevenueYOY` float DEFAULT NULL,
  `tRevenueQOQ` float DEFAULT NULL,
  `revenueYOY` float DEFAULT NULL,
  `revenueQOQ` float DEFAULT NULL,
  `operProfitYOY` float DEFAULT NULL,
  `operProfitQOQ` float DEFAULT NULL,
  `niYOY` float DEFAULT NULL,
  `niQOQ` float DEFAULT NULL,
  `niAttrPYOY` float DEFAULT NULL,
  `niAttrPQOQ` float DEFAULT NULL,
  `niAttrPCutYOY` float DEFAULT NULL,
  `niAttrPCutQOQ` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtindirtnpitget`
--

DROP TABLE IF EXISTS `yq_fdmtindirtnpitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtindirtnpitget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `grossMARgin` float DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `npMARgin` float DEFAULT NULL,
  `ROE` float DEFAULT NULL,
  `ROEA` float DEFAULT NULL,
  `ROEW` float DEFAULT NULL,
  `ROECut` float DEFAULT NULL,
  `ROECutW` float DEFAULT NULL,
  `ROA` float DEFAULT NULL,
  `ROAEBIT` float DEFAULT NULL,
  `ROIC` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtinditrnovrpitget`
--

DROP TABLE IF EXISTS `yq_fdmtinditrnovrpitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtinditrnovrpitget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `faTurnover` float DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `tfaTurnover` float DEFAULT NULL,
  `caTurnover` float DEFAULT NULL,
  `taTurnover` float DEFAULT NULL,
  `invenTurnover` float DEFAULT NULL,
  `daysInven` float DEFAULT NULL,
  `ARTurnover` float DEFAULT NULL,
  `daysAR` float DEFAULT NULL,
  `operCycle` float DEFAULT NULL,
  `APTurnover` float DEFAULT NULL,
  `daysAP` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtisqpitget`
--

DROP TABLE IF EXISTS `yq_fdmtisqpitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtisqpitget` (
  `secID` varchar(14) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `ticker` varchar(14) DEFAULT NULL,
  `secShortName` varchar(14) DEFAULT NULL,
  `exchangeCD` varchar(14) DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `isNew` int(11) DEFAULT NULL,
  `isCalc` int(11) DEFAULT NULL,
  `tRevenue` float DEFAULT NULL,
  `revenue` float DEFAULT NULL,
  `intIncome` float DEFAULT NULL,
  `premEarned` float DEFAULT NULL,
  `commisIncome` float DEFAULT NULL,
  `TCogs` float DEFAULT NULL,
  `COGS` float DEFAULT NULL,
  `intExp` float DEFAULT NULL,
  `commisExp` float DEFAULT NULL,
  `premRefund` float DEFAULT NULL,
  `NCompensPayout` float DEFAULT NULL,
  `reserInsurContr` float DEFAULT NULL,
  `policyDivPayt` float DEFAULT NULL,
  `reinsurExp` float DEFAULT NULL,
  `bizTaxSurchg` float DEFAULT NULL,
  `sellExp` float DEFAULT NULL,
  `adminExp` float DEFAULT NULL,
  `finanExp` float DEFAULT NULL,
  `assetsImpairLoss` float DEFAULT NULL,
  `fValueChgGain` float DEFAULT NULL,
  `investIncome` float DEFAULT NULL,
  `AJInvestIncome` float DEFAULT NULL,
  `forexGain` float DEFAULT NULL,
  `assetsDispGain` float DEFAULT NULL,
  `othGain` float DEFAULT NULL,
  `operateProfit` float DEFAULT NULL,
  `NoperateIncome` float DEFAULT NULL,
  `NoperateExp` float DEFAULT NULL,
  `NCADisploss` float DEFAULT NULL,
  `TProfit` float DEFAULT NULL,
  `incomeTax` float DEFAULT NULL,
  `NIncome` float DEFAULT NULL,
  `goingConcernNI` float DEFAULT NULL,
  `quitConcernNI` float DEFAULT NULL,
  `NIncomeAttrP` float DEFAULT NULL,
  `minorityGain` float DEFAULT NULL,
  `othComprIncome` float DEFAULT NULL,
  `TComprIncome` float DEFAULT NULL,
  `comprIncAttrP` float DEFAULT NULL,
  `comprIncAttrMS` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtisttmpitget`
--

DROP TABLE IF EXISTS `yq_fdmtisttmpitget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtisttmpitget` (
  `secID` varchar(20) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `symbol` varchar(6) NOT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `endDate` date NOT NULL,
  `publishDate` date NOT NULL,
  `isNew` float DEFAULT NULL,
  `isCalc` float DEFAULT NULL,
  `tRevenue` float DEFAULT NULL,
  `revenue` float DEFAULT NULL,
  `intIncome` float DEFAULT NULL,
  `premEarned` float DEFAULT NULL,
  `commisIncome` float DEFAULT NULL,
  `TCogs` float DEFAULT NULL,
  `COGS` float DEFAULT NULL,
  `intExp` float DEFAULT NULL,
  `commisExp` float DEFAULT NULL,
  `premRefund` float DEFAULT NULL,
  `NCompensPayout` float DEFAULT NULL,
  `reserInsurContr` float DEFAULT NULL,
  `policyDivPayt` float DEFAULT NULL,
  `reinsurExp` float DEFAULT NULL,
  `bizTaxSurchg` float DEFAULT NULL,
  `sellExp` float DEFAULT NULL,
  `adminExp` float DEFAULT NULL,
  `finanExp` float DEFAULT NULL,
  `assetsImpairLoss` float DEFAULT NULL,
  `fValueChgGain` float DEFAULT NULL,
  `investIncome` float DEFAULT NULL,
  `AJInvestIncome` float DEFAULT NULL,
  `forexGain` float DEFAULT NULL,
  `assetsDispGain` float DEFAULT NULL,
  `othGain` float DEFAULT NULL,
  `operateProfit` float DEFAULT NULL,
  `NoperateIncome` float DEFAULT NULL,
  `NoperateExp` float DEFAULT NULL,
  `NCADisploss` float DEFAULT NULL,
  `TProfit` float DEFAULT NULL,
  `incomeTax` float DEFAULT NULL,
  `NIncome` float DEFAULT NULL,
  `goingConcernNI` float DEFAULT NULL,
  `quitConcernNI` float DEFAULT NULL,
  `NIncomeAttrP` float DEFAULT NULL,
  `minorityGain` float DEFAULT NULL,
  `othComprIncome` float DEFAULT NULL,
  `TComprIncome` float DEFAULT NULL,
  `comprIncAttrP` float DEFAULT NULL,
  `comprIncAttrMS` float DEFAULT NULL,
  PRIMARY KEY (`symbol`,`endDate`,`publishDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtmainopernget`
--

DROP TABLE IF EXISTS `yq_fdmtmainopernget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtmainopernget` (
  `partyID` bigint(20) DEFAULT NULL,
  `secID` text,
  `symbol` text,
  `secShortName` text,
  `exchangeCD` text,
  `actPubtime` text,
  `publishDate` text,
  `endDate` text,
  `fiscalPeriod` bigint(20) DEFAULT NULL,
  `mergeFlag` bigint(20) DEFAULT NULL,
  `classifCD` bigint(20) DEFAULT NULL,
  `isLatest` bigint(20) DEFAULT NULL,
  `industry` text,
  `itemParentNo` double DEFAULT NULL,
  `itemNo` bigint(20) DEFAULT NULL,
  `itemName` text,
  `revenue` double DEFAULT NULL,
  `revPctge` double DEFAULT NULL,
  `revIsPctge` double DEFAULT NULL,
  `tRevIsPctge` double DEFAULT NULL,
  `cogs` double DEFAULT NULL,
  `costPctge` double DEFAULT NULL,
  `cogsIsPctge` double DEFAULT NULL,
  `tCogsIsPctge` double DEFAULT NULL,
  `grossProfit` double DEFAULT NULL,
  `grossMargin` double DEFAULT NULL,
  `updateTime` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fdmtmainopernget_update`
--

DROP TABLE IF EXISTS `yq_fdmtmainopernget_update`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fdmtmainopernget_update` (
  `partyID` float DEFAULT NULL,
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `actPubtime` datetime DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `fiscalPeriod` float DEFAULT NULL,
  `mergeFlag` float DEFAULT NULL,
  `classifCD` float DEFAULT NULL,
  `isLatest` float DEFAULT NULL,
  `industry` varchar(20) DEFAULT NULL,
  `itemParentNo` float DEFAULT NULL,
  `itemNo` float DEFAULT NULL,
  `itemName` text,
  `revenue` float DEFAULT NULL,
  `revPctge` float DEFAULT NULL,
  `revIsPctge` float DEFAULT NULL,
  `tRevIsPctge` float DEFAULT NULL,
  `cogs` float DEFAULT NULL,
  `costPctge` float DEFAULT NULL,
  `cogsIsPctge` float DEFAULT NULL,
  `tCogsIsPctge` float DEFAULT NULL,
  `grossProfit` float DEFAULT NULL,
  `grossMargin` float DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fundassetsget_s51`
--

DROP TABLE IF EXISTS `yq_fundassetsget_s51`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fundassetsget_s51` (
  `secID` varchar(14) DEFAULT NULL,
  `ticker` varchar(14) NOT NULL,
  `secShortName` varchar(50) DEFAULT NULL,
  `reportDate` date NOT NULL,
  `totalAsset` float DEFAULT NULL,
  `netAsset` float DEFAULT NULL,
  `equityMarketValue` float DEFAULT NULL,
  `bondMarketValue` float DEFAULT NULL,
  `cashMarketValue` float DEFAULT NULL,
  `otherMarketValue` float DEFAULT NULL,
  `equityRatioInTa` float DEFAULT NULL,
  `bondRatioInTa` float DEFAULT NULL,
  `cashRatioInTa` float DEFAULT NULL,
  `otherRatioInTa` float DEFAULT NULL,
  `publishDate` date DEFAULT NULL,
  `currencyCd` varchar(14) DEFAULT NULL,
  `updateTime` datetime NOT NULL,
  PRIMARY KEY (`ticker`,`reportDate`,`updateTime`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fundetfconsget`
--

DROP TABLE IF EXISTS `yq_fundetfconsget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fundetfconsget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(8) NOT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(6) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `consID` varchar(20) DEFAULT NULL,
  `consTicker` varchar(8) NOT NULL,
  `consName` varchar(20) DEFAULT NULL,
  `consExchangeCD` varchar(6) DEFAULT NULL,
  `quantity` float DEFAULT NULL,
  `cashSubsSign` float DEFAULT NULL,
  `CashRatio` float DEFAULT NULL,
  `fixedCahsAmount` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`consTicker`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_fundetfprlistget`
--

DROP TABLE IF EXISTS `yq_fundetfprlistget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_fundetfprlistget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(8) NOT NULL,
  `fundShortName` varchar(20) DEFAULT NULL,
  `underLyingIndex` varchar(20) DEFAULT NULL,
  `idxShortName` varchar(20) DEFAULT NULL,
  `preTradeDate` date DEFAULT NULL,
  `cashComp` float DEFAULT NULL,
  `NAVPreCu` float DEFAULT NULL,
  `NAV` float DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `estCahComp` float DEFAULT NULL,
  `maxCashRatio` float DEFAULT NULL,
  `creationUnit` float DEFAULT NULL,
  `ifIOPV` float DEFAULT NULL,
  `ifPurchaseble` float DEFAULT NULL,
  `ifRedeemable` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_futuget`
--

DROP TABLE IF EXISTS `yq_futuget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_futuget` (
  `secID` text,
  `listDate` text,
  `secFullName` text,
  `secShortName` text,
  `ticker` text,
  `exchangeCD` text,
  `contractType` text,
  `contractObject` text,
  `priceUnit` text,
  `minChgPriceNum` double DEFAULT NULL,
  `minChgPriceUnit` text,
  `priceValidDecimal` bigint(20) DEFAULT NULL,
  `limitUpNum` double DEFAULT NULL,
  `limitUpUnit` text,
  `limitDownNum` double DEFAULT NULL,
  `limitDownUnit` text,
  `transCurrCD` text,
  `contMultNum` bigint(20) DEFAULT NULL,
  `contMultUnit` text,
  `tradeMarginRatio` double DEFAULT NULL,
  `deliYear` bigint(20) DEFAULT NULL,
  `deliMonth` bigint(20) DEFAULT NULL,
  `lastTradeDate` text,
  `firstDeliDate` text,
  `lastDeliDate` text,
  `deliMethod` text,
  `tradeCommiNum` double DEFAULT NULL,
  `tradeCommiUnit` text,
  `deliCommiNum` double DEFAULT NULL,
  `deliCommiUnit` text,
  `listBasisPrice` double DEFAULT NULL,
  `contractStatus` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_index`
--

DROP TABLE IF EXISTS `yq_index`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_index` (
  `indexID` varchar(20) NOT NULL,
  `symbol` varchar(11) DEFAULT NULL,
  `porgFullName` varchar(60) DEFAULT NULL,
  `secShortName` varchar(40) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `preCloseIndex` float DEFAULT NULL,
  `openIndex` float DEFAULT NULL,
  `lowestIndex` float DEFAULT NULL,
  `highestIndex` float DEFAULT NULL,
  `closeIndex` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `CHG` float DEFAULT NULL,
  `CHGPct` float DEFAULT NULL,
  PRIMARY KEY (`indexID`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_index_month`
--

DROP TABLE IF EXISTS `yq_index_month`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_index_month` (
  `indexID` varchar(20) DEFAULT NULL,
  `symbol` varchar(11) DEFAULT NULL,
  `secShortName` varchar(60) DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `tradeDays` float DEFAULT NULL,
  `preClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `avgPrice` float DEFAULT NULL,
  `mAvgReyurn` float DEFAULT NULL,
  `yReturn` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_industry`
--

DROP TABLE IF EXISTS `yq_industry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_industry` (
  `secID` text,
  `ticker` varchar(6) DEFAULT NULL,
  `exchangeCD` text,
  `secShortName` text,
  `secFullName` text,
  `partyID` bigint(20) DEFAULT NULL,
  `industryVersionCD` bigint(20) DEFAULT NULL,
  `industry` text,
  `industryID` bigint(20) DEFAULT NULL,
  `industrySymbol` text,
  `intodate` date DEFAULT NULL,
  `outdate` date DEFAULT NULL,
  `isNew` bigint(20) DEFAULT NULL,
  `industryID1` bigint(20) DEFAULT NULL,
  `industryName1` text,
  `industryID2` bigint(20) DEFAULT NULL,
  `industryName2` text,
  `industryID3` bigint(20) DEFAULT NULL,
  `industryName3` text,
  `industryID4` bigint(20) DEFAULT NULL,
  `IndustryName4` text,
  `equType` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_industry_sw`
--

DROP TABLE IF EXISTS `yq_industry_sw`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_industry_sw` (
  `secID` text,
  `ticker` text,
  `exchangeCD` text,
  `secShortName` text,
  `secFullName` text,
  `partyID` bigint(20) DEFAULT NULL,
  `industryVersionCD` bigint(20) DEFAULT NULL,
  `industry` text,
  `industryID` bigint(20) DEFAULT NULL,
  `industrySymbol` bigint(20) DEFAULT NULL,
  `intoDate` text,
  `outDate` text,
  `isNew` bigint(20) DEFAULT NULL,
  `industryID1` bigint(20) DEFAULT NULL,
  `industryName1` text,
  `industryID2` bigint(20) DEFAULT NULL,
  `industryName2` text,
  `industryID3` bigint(20) DEFAULT NULL,
  `industryName3` text,
  `IndustryID4` double DEFAULT NULL,
  `IndustryName4` double DEFAULT NULL,
  `equType` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mdswbackget`
--

DROP TABLE IF EXISTS `yq_mdswbackget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mdswbackget` (
  `secID` varchar(14) DEFAULT NULL,
  `ticker` varchar(14) DEFAULT NULL,
  `secShortName` varchar(14) DEFAULT NULL,
  `exchangeCD` varchar(14) DEFAULT NULL,
  `secFullName` varchar(30) DEFAULT NULL,
  `partyID` int(11) DEFAULT NULL,
  `oldTypeName` varchar(10) DEFAULT NULL,
  `intoDate` date DEFAULT NULL,
  `outDate` date DEFAULT NULL,
  `isNew` int(11) DEFAULT NULL,
  `industryID1` int(11) DEFAULT NULL,
  `industryName1` varchar(10) DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktequdadjafget`
--

DROP TABLE IF EXISTS `yq_mktequdadjafget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktequdadjafget` (
  `secID` varchar(12) DEFAULT NULL,
  `ticker` varchar(12) NOT NULL,
  `secShortName` varchar(12) DEFAULT NULL,
  `exchangeCD` varchar(12) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `preClosePrice` float DEFAULT NULL,
  `actPreClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `dealAmount` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `accumAdjFactor` float DEFAULT NULL,
  `negMarketValue` float DEFAULT NULL,
  `isOpen` int(11) DEFAULT NULL,
  `marketValue` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktequwadjafget`
--

DROP TABLE IF EXISTS `yq_mktequwadjafget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktequwadjafget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(10) NOT NULL,
  `secShortName` varchar(10) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `weekBeginDate` date DEFAULT NULL,
  `endDate` date NOT NULL,
  `tradeDays` float DEFAULT NULL,
  `preClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `weekreturn` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `avgTurnoverRate` float DEFAULT NULL,
  `varReturn100` float DEFAULT NULL,
  `sdReturn100` float DEFAULT NULL,
  `avgReturn100` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`endDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktfutmlrget`
--

DROP TABLE IF EXISTS `yq_mktfutmlrget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktfutmlrget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `partyShortName` varchar(20) NOT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `longVol` float DEFAULT NULL,
  `CHG` float DEFAULT NULL,
  `rank` float NOT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`partyShortName`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktfutmsrget`
--

DROP TABLE IF EXISTS `yq_mktfutmsrget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktfutmsrget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `secShortName` varchar(30) DEFAULT NULL,
  `partyShortName` varchar(30) NOT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `shortVol` float DEFAULT NULL,
  `CHG` float DEFAULT NULL,
  `rank` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`partyShortName`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktfutmtrget`
--

DROP TABLE IF EXISTS `yq_mktfutmtrget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktfutmtrget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `secShortName` varchar(30) DEFAULT NULL,
  `partyShortName` varchar(30) NOT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `turnoverVol` float DEFAULT NULL,
  `CHG` float DEFAULT NULL,
  `rank` float NOT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`partyShortName`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktfutwrdget`
--

DROP TABLE IF EXISTS `yq_mktfutwrdget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktfutwrdget` (
  `tradeDate` date NOT NULL,
  `contractObject` varchar(20) CHARACTER SET gbk NOT NULL,
  `exchangeCD` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `unit` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `warehouse` varchar(20) CHARACTER SET gbk NOT NULL,
  `preWrVOL` float DEFAULT NULL,
  `wrVOL` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  PRIMARY KEY (`tradeDate`,`warehouse`,`contractObject`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktidxdevalget`
--

DROP TABLE IF EXISTS `yq_mktidxdevalget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktidxdevalget` (
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) NOT NULL,
  `progFullName` varchar(20) DEFAULT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(20) DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `indexMarketValue` float DEFAULT NULL,
  `indexIncome` float DEFAULT NULL,
  `indexAttrP` float DEFAULT NULL,
  `PEValue` float DEFAULT NULL,
  `PEType` float NOT NULL,
  `PB` float DEFAULT NULL,
  `ROE` float DEFAULT NULL,
  `indexValue` float DEFAULT NULL,
  `negIndexValue` float DEFAULT NULL,
  `turnoverRate` float DEFAULT NULL,
  `upNum` float DEFAULT NULL,
  `downNum` float DEFAULT NULL,
  `equalNum` float DEFAULT NULL,
  `divYield` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`,`PEType`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktidxwget`
--

DROP TABLE IF EXISTS `yq_mktidxwget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktidxwget` (
  `indexID` varchar(20) DEFAULT NULL,
  `ticker` varchar(30) NOT NULL,
  `secShortName` varchar(20) DEFAULT NULL,
  `endDate` date NOT NULL,
  `tradeDays` float DEFAULT NULL,
  `preClosePrice` float NOT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `avgPrice` float DEFAULT NULL,
  `wAvgReturn` float DEFAULT NULL,
  `yReturn` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`endDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktmfutdget`
--

DROP TABLE IF EXISTS `yq_mktmfutdget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktmfutdget` (
  `secID` varchar(20) CHARACTER SET gbk NOT NULL,
  `ticker` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `exchangeCD` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `secShortName` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `secShortNameEN` varchar(50) CHARACTER SET gbk DEFAULT NULL,
  `tradeDate` date NOT NULL,
  `contractObject` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `contractMark` varchar(20) CHARACTER SET gbk DEFAULT NULL,
  `preSettlePrice` float DEFAULT NULL,
  `preClosePrice` float DEFAULT NULL,
  `openPrice` float DEFAULT NULL,
  `highestPrice` float DEFAULT NULL,
  `lowestPrice` float DEFAULT NULL,
  `settlePrice` float DEFAULT NULL,
  `closePrice` float DEFAULT NULL,
  `turnoverVol` float DEFAULT NULL,
  `turnoverValue` float DEFAULT NULL,
  `openInt` float DEFAULT NULL,
  `chg` float DEFAULT NULL,
  `chg1` float DEFAULT NULL,
  `chgPct` float DEFAULT NULL,
  `mainCon` float DEFAULT NULL,
  `smainCon` float DEFAULT NULL,
  PRIMARY KEY (`secID`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktstockfactorsonedayget`
--

DROP TABLE IF EXISTS `yq_mktstockfactorsonedayget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktstockfactorsonedayget` (
  `secID` varchar(12) DEFAULT NULL,
  `ticker` varchar(12) NOT NULL,
  `tradeDate` date NOT NULL,
  `AccountsPayablesTDays` float DEFAULT NULL,
  `AccountsPayablesTRate` float DEFAULT NULL,
  `AdminiExpenseRate` float DEFAULT NULL,
  `ARTDays` float DEFAULT NULL,
  `ARTRate` float DEFAULT NULL,
  `ASSI` float DEFAULT NULL,
  `BLEV` float DEFAULT NULL,
  `BondsPayableToAsset` float DEFAULT NULL,
  `CashRateOfSales` float DEFAULT NULL,
  `CashToCurrentLiability` float DEFAULT NULL,
  `CMRA` float DEFAULT NULL,
  `CTOP` float DEFAULT NULL,
  `CTP5` float DEFAULT NULL,
  `CurrentAssetsRatio` float DEFAULT NULL,
  `CurrentAssetsTRate` float DEFAULT NULL,
  `CurrentRatio` float DEFAULT NULL,
  `DAVOL10` float DEFAULT NULL,
  `DAVOL20` float DEFAULT NULL,
  `DAVOL5` float DEFAULT NULL,
  `DDNBT` float DEFAULT NULL,
  `DDNCR` float DEFAULT NULL,
  `DDNSR` float DEFAULT NULL,
  `DebtEquityRatio` float DEFAULT NULL,
  `DebtsAssetRatio` float DEFAULT NULL,
  `DHILO` float DEFAULT NULL,
  `DilutedEPS` float DEFAULT NULL,
  `DVRAT` float DEFAULT NULL,
  `EBITToTOR` float DEFAULT NULL,
  `EGRO` float DEFAULT NULL,
  `EMA10` float DEFAULT NULL,
  `EMA120` float DEFAULT NULL,
  `EMA20` float DEFAULT NULL,
  `EMA5` float DEFAULT NULL,
  `EMA60` float DEFAULT NULL,
  `EPS` float DEFAULT NULL,
  `EquityFixedAssetRatio` float DEFAULT NULL,
  `EquityToAsset` float DEFAULT NULL,
  `EquityTRate` float DEFAULT NULL,
  `ETOP` float DEFAULT NULL,
  `ETP5` float DEFAULT NULL,
  `FinancialExpenseRate` float DEFAULT NULL,
  `FinancingCashGrowRate` float DEFAULT NULL,
  `FixAssetRatio` float DEFAULT NULL,
  `FixedAssetsTRate` float DEFAULT NULL,
  `GrossIncomeRatio` float DEFAULT NULL,
  `HBETA` float DEFAULT NULL,
  `HSIGMA` float DEFAULT NULL,
  `IntangibleAssetRatio` float DEFAULT NULL,
  `InventoryTDays` float DEFAULT NULL,
  `InventoryTRate` float DEFAULT NULL,
  `InvestCashGrowRate` float DEFAULT NULL,
  `LCAP` float DEFAULT NULL,
  `LFLO` float DEFAULT NULL,
  `LongDebtToAsset` float DEFAULT NULL,
  `LongDebtToWorkingCapital` float DEFAULT NULL,
  `LongTermDebtToAsset` float DEFAULT NULL,
  `MA10` float DEFAULT NULL,
  `MA120` float DEFAULT NULL,
  `MA20` float DEFAULT NULL,
  `MA5` float DEFAULT NULL,
  `MA60` float DEFAULT NULL,
  `MAWVAD` float DEFAULT NULL,
  `MFI` float DEFAULT NULL,
  `MLEV` float DEFAULT NULL,
  `NetAssetGrowRate` float DEFAULT NULL,
  `NetProfitGrowRate` float DEFAULT NULL,
  `NetProfitRatio` float DEFAULT NULL,
  `NOCFToOperatingNI` float DEFAULT NULL,
  `NonCurrentAssetsRatio` float DEFAULT NULL,
  `NPParentCompanyGrowRate` float DEFAULT NULL,
  `NPToTOR` float DEFAULT NULL,
  `OperatingExpenseRate` float DEFAULT NULL,
  `OperatingProfitGrowRate` float DEFAULT NULL,
  `OperatingProfitRatio` float DEFAULT NULL,
  `OperatingProfitToTOR` float DEFAULT NULL,
  `OperatingRevenueGrowRate` float DEFAULT NULL,
  `OperCashGrowRate` float DEFAULT NULL,
  `OperCashInToCurrentLiability` float DEFAULT NULL,
  `PB` float DEFAULT NULL,
  `PCF` float DEFAULT NULL,
  `PE` float DEFAULT NULL,
  `PS` float DEFAULT NULL,
  `PSY` float DEFAULT NULL,
  `QuickRatio` float DEFAULT NULL,
  `REVS10` float DEFAULT NULL,
  `REVS20` float DEFAULT NULL,
  `REVS5` float DEFAULT NULL,
  `ROA` float DEFAULT NULL,
  `ROA5` float DEFAULT NULL,
  `ROE` float DEFAULT NULL,
  `ROE5` float DEFAULT NULL,
  `RSI` float DEFAULT NULL,
  `RSTR12` float DEFAULT NULL,
  `RSTR24` float DEFAULT NULL,
  `SalesCostRatio` float DEFAULT NULL,
  `SaleServiceCashToOR` float DEFAULT NULL,
  `SUE` float DEFAULT NULL,
  `TaxRatio` float DEFAULT NULL,
  `TOBT` float DEFAULT NULL,
  `TotalAssetGrowRate` float DEFAULT NULL,
  `TotalAssetsTRate` float DEFAULT NULL,
  `TotalProfitCostRatio` float DEFAULT NULL,
  `TotalProfitGrowRate` float DEFAULT NULL,
  `VOL10` float DEFAULT NULL,
  `VOL120` float DEFAULT NULL,
  `VOL20` float DEFAULT NULL,
  `VOL240` float DEFAULT NULL,
  `VOL5` float DEFAULT NULL,
  `VOL60` float DEFAULT NULL,
  `WVAD` float DEFAULT NULL,
  `REC` float DEFAULT NULL,
  `DAREC` float DEFAULT NULL,
  `GREC` float DEFAULT NULL,
  `FY12P` float DEFAULT NULL,
  `DAREV` float DEFAULT NULL,
  `GREV` float DEFAULT NULL,
  `SFY12P` float DEFAULT NULL,
  `DASREV` float DEFAULT NULL,
  `GSREV` float DEFAULT NULL,
  `FEARNG` float DEFAULT NULL,
  `FSALESG` float DEFAULT NULL,
  `TA2EV` float DEFAULT NULL,
  `CFO2EV` float DEFAULT NULL,
  `ACCA` float DEFAULT NULL,
  `DEGM` float DEFAULT NULL,
  `SUOI` float DEFAULT NULL,
  `EARNMOM` float DEFAULT NULL,
  `FiftyTwoWeekHigh` float DEFAULT NULL,
  `Volatility` float DEFAULT NULL,
  `Skewness` float DEFAULT NULL,
  `ILLIQUIDITY` float DEFAULT NULL,
  `BackwardADJ` float DEFAULT NULL,
  `MACD` float DEFAULT NULL,
  `ADTM` float DEFAULT NULL,
  `ATR14` float DEFAULT NULL,
  `ATR6` float DEFAULT NULL,
  `BIAS10` float DEFAULT NULL,
  `BIAS20` float DEFAULT NULL,
  `BIAS5` float DEFAULT NULL,
  `BIAS60` float DEFAULT NULL,
  `BollDown` float DEFAULT NULL,
  `BollUp` float DEFAULT NULL,
  `CCI10` float DEFAULT NULL,
  `CCI20` float DEFAULT NULL,
  `CCI5` float DEFAULT NULL,
  `CCI88` float DEFAULT NULL,
  `KDJ_K` float DEFAULT NULL,
  `KDJ_D` float DEFAULT NULL,
  `KDJ_J` float DEFAULT NULL,
  `ROC6` float DEFAULT NULL,
  `ROC20` float DEFAULT NULL,
  `SBM` float DEFAULT NULL,
  `STM` float DEFAULT NULL,
  `UpRVI` float DEFAULT NULL,
  `DownRVI` float DEFAULT NULL,
  `RVI` float DEFAULT NULL,
  `SRMI` float DEFAULT NULL,
  `ChandeSD` float DEFAULT NULL,
  `ChandeSU` float DEFAULT NULL,
  `CMO` float DEFAULT NULL,
  `DBCD` float DEFAULT NULL,
  `ARC` float DEFAULT NULL,
  `OBV` float DEFAULT NULL,
  `OBV6` float DEFAULT NULL,
  `OBV20` float DEFAULT NULL,
  `TVMA20` float DEFAULT NULL,
  `TVMA6` float DEFAULT NULL,
  `TVSTD20` float DEFAULT NULL,
  `TVSTD6` float DEFAULT NULL,
  `VDEA` float DEFAULT NULL,
  `VDIFF` float DEFAULT NULL,
  `VEMA10` float DEFAULT NULL,
  `VEMA12` float DEFAULT NULL,
  `VEMA26` float DEFAULT NULL,
  `VEMA5` float DEFAULT NULL,
  `VMACD` float DEFAULT NULL,
  `VOSC` float DEFAULT NULL,
  `VR` float DEFAULT NULL,
  `VROC12` float DEFAULT NULL,
  `VROC6` float DEFAULT NULL,
  `VSTD10` float DEFAULT NULL,
  `VSTD20` float DEFAULT NULL,
  `KlingerOscillator` float DEFAULT NULL,
  `MoneyFlow20` float DEFAULT NULL,
  `AD` float DEFAULT NULL,
  `AD20` float DEFAULT NULL,
  `AD6` float DEFAULT NULL,
  `CoppockCurve` float DEFAULT NULL,
  `ASI` float DEFAULT NULL,
  `ChaikinOscillator` float DEFAULT NULL,
  `ChaikinVolatility` float DEFAULT NULL,
  `EMV14` float DEFAULT NULL,
  `EMV6` float DEFAULT NULL,
  `plusDI` float DEFAULT NULL,
  `minusDI` float DEFAULT NULL,
  `ADX` float DEFAULT NULL,
  `ADXR` float DEFAULT NULL,
  `Aroon` float DEFAULT NULL,
  `AroonDown` float DEFAULT NULL,
  `AroonUp` float DEFAULT NULL,
  `DEA` float DEFAULT NULL,
  `DIFF` float DEFAULT NULL,
  `DDI` float DEFAULT NULL,
  `DIZ` float DEFAULT NULL,
  `DIF` float DEFAULT NULL,
  `MTM` float DEFAULT NULL,
  `MTMMA` float DEFAULT NULL,
  `PVT` float DEFAULT NULL,
  `PVT6` float DEFAULT NULL,
  `PVT12` float DEFAULT NULL,
  `TRIX5` float DEFAULT NULL,
  `TRIX10` float DEFAULT NULL,
  `UOS` float DEFAULT NULL,
  `MA10RegressCoeff12` float DEFAULT NULL,
  `MA10RegressCoeff6` float DEFAULT NULL,
  `PLRC6` float DEFAULT NULL,
  `PLRC12` float DEFAULT NULL,
  `SwingIndex` float DEFAULT NULL,
  `Ulcer10` float DEFAULT NULL,
  `Ulcer5` float DEFAULT NULL,
  `Hurst` float DEFAULT NULL,
  `ACD6` float DEFAULT NULL,
  `ACD20` float DEFAULT NULL,
  `EMA12` float DEFAULT NULL,
  `EMA26` float DEFAULT NULL,
  `APBMA` float DEFAULT NULL,
  `BBI` float DEFAULT NULL,
  `BBIC` float DEFAULT NULL,
  `TEMA10` float DEFAULT NULL,
  `TEMA5` float DEFAULT NULL,
  `MA10Close` float DEFAULT NULL,
  `AR` float DEFAULT NULL,
  `BR` float DEFAULT NULL,
  `ARBR` float DEFAULT NULL,
  `CR20` float DEFAULT NULL,
  `MassIndex` float DEFAULT NULL,
  `BearPower` float DEFAULT NULL,
  `BullPower` float DEFAULT NULL,
  `Elder` float DEFAULT NULL,
  `NVI` float DEFAULT NULL,
  `PVI` float DEFAULT NULL,
  `RC12` float DEFAULT NULL,
  `RC24` float DEFAULT NULL,
  `JDQS20` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8
/*!50100 PARTITION BY KEY (ticker)
PARTITIONS 50 */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_mktstockfactorsonedayproget`
--

DROP TABLE IF EXISTS `yq_mktstockfactorsonedayproget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_mktstockfactorsonedayproget` (
  `secID` varchar(12) DEFAULT NULL,
  `ticker` varchar(12) NOT NULL,
  `tradeDate` date NOT NULL,
  `CostTTM` float DEFAULT NULL,
  `NetProfitTTM` float DEFAULT NULL,
  `RealizedVolatility` float DEFAULT NULL,
  `Beta20` float DEFAULT NULL,
  `LossVariance20` float DEFAULT NULL,
  `TRevenueTTM` float DEFAULT NULL,
  `SGRO` float DEFAULT NULL,
  `FCFE` float DEFAULT NULL,
  `TEAP` float DEFAULT NULL,
  `DividendCover` float DEFAULT NULL,
  `OperCashFlowPS` float DEFAULT NULL,
  `OperatingRevenueGrowRate3Y` float DEFAULT NULL,
  `ROEDiluted` float DEFAULT NULL,
  `TotalFixedAssets` float DEFAULT NULL,
  `Beta60` float DEFAULT NULL,
  `TSEPToTotalCapital` float DEFAULT NULL,
  `NOCFToNetDebt` float DEFAULT NULL,
  `FinanExpenseTTM` float DEFAULT NULL,
  `REVS5m60` float DEFAULT NULL,
  `RetainedEarningsPS` float DEFAULT NULL,
  `Price1M` float DEFAULT NULL,
  `EBIAT` float DEFAULT NULL,
  `REVS120` float DEFAULT NULL,
  `TangibleAToInteBearDebt` float DEFAULT NULL,
  `GainLossVarianceRatio120` float DEFAULT NULL,
  `TreynorRatio120` float DEFAULT NULL,
  `Price3M` float DEFAULT NULL,
  `SalesExpenseTTM` float DEFAULT NULL,
  `NPFromOperatingTTM` float DEFAULT NULL,
  `Beta252` float DEFAULT NULL,
  `CashConversionCycle` float DEFAULT NULL,
  `ROAEBIT` float DEFAULT NULL,
  `PSIndu` float DEFAULT NULL,
  `GainLossVarianceRatio60` float DEFAULT NULL,
  `SharpeRatio20` float DEFAULT NULL,
  `TCostTTM` float DEFAULT NULL,
  `GainVariance120` float DEFAULT NULL,
  `Rank1M` float DEFAULT NULL,
  `Kurtosis120` float DEFAULT NULL,
  `TangibleAToNetDebt` float DEFAULT NULL,
  `NetIntExpense` float DEFAULT NULL,
  `CashRateOfSalesLatest` float DEFAULT NULL,
  `OperatingCycle` float DEFAULT NULL,
  `NonOperatingNPTTM` float DEFAULT NULL,
  `NetOperateCFTTM` float DEFAULT NULL,
  `PEHist250` float DEFAULT NULL,
  `NPFromValueChgTTM` float DEFAULT NULL,
  `NetNonOIToTPLatest` float DEFAULT NULL,
  `NetWorkingCapital` float DEFAULT NULL,
  `NetProfitGrowRate5Y` float DEFAULT NULL,
  `InformationRatio60` float DEFAULT NULL,
  `NegMktValue` float DEFAULT NULL,
  `ROAEBITTTM` float DEFAULT NULL,
  `NetInvestCFTTM` float DEFAULT NULL,
  `NPCutToNP` float DEFAULT NULL,
  `NOCFToOperatingNILatest` float DEFAULT NULL,
  `PeriodCostsRate` float DEFAULT NULL,
  `NetProfitAPTTM` float DEFAULT NULL,
  `TProfitTTM` float DEFAULT NULL,
  `NetDebt` float DEFAULT NULL,
  `PEG3Y` float DEFAULT NULL,
  `SuperQuickRatio` float DEFAULT NULL,
  `UndividedProfitPS` float DEFAULT NULL,
  `Variance60` float DEFAULT NULL,
  `InvestRAssociatesToTP` float DEFAULT NULL,
  `Alpha20` float DEFAULT NULL,
  `CashDividendCover` float DEFAULT NULL,
  `Price1Y` float DEFAULT NULL,
  `TORPS` float DEFAULT NULL,
  `GainVariance60` float DEFAULT NULL,
  `REVS250` float DEFAULT NULL,
  `TORPSLatest` float DEFAULT NULL,
  `CapitalSurplusFundPS` float DEFAULT NULL,
  `RSTR504` float DEFAULT NULL,
  `REVS5Indu1` float DEFAULT NULL,
  `InvestRAssociatesToTPLatest` float DEFAULT NULL,
  `NOCFToInterestBearDebt` float DEFAULT NULL,
  `CashFlowPS` float DEFAULT NULL,
  `ROEWeighted` float DEFAULT NULL,
  `GrossProfit` float DEFAULT NULL,
  `NIAP` float DEFAULT NULL,
  `SaleServiceRenderCashTTM` float DEFAULT NULL,
  `DASTD` float DEFAULT NULL,
  `NetAssetPS` float DEFAULT NULL,
  `OperatingNIToTP` float DEFAULT NULL,
  `AdminExpenseTTM` float DEFAULT NULL,
  `SurplusReserveFundPS` float DEFAULT NULL,
  `IntFreeCL` float DEFAULT NULL,
  `STOA` float DEFAULT NULL,
  `ForwardPE` float DEFAULT NULL,
  `EnterpriseFCFPS` float DEFAULT NULL,
  `NOCFToTLiability` float DEFAULT NULL,
  `GainVariance20` float DEFAULT NULL,
  `LossVariance60` float DEFAULT NULL,
  `CETOP` float DEFAULT NULL,
  `Volumn1M` float DEFAULT NULL,
  `PEHist120` float DEFAULT NULL,
  `TreynorRatio60` float DEFAULT NULL,
  `WorkingCapital` float DEFAULT NULL,
  `OperateNetIncome` float DEFAULT NULL,
  `STOQ` float DEFAULT NULL,
  `PEHist20` float DEFAULT NULL,
  `EgibsLong` float DEFAULT NULL,
  `Variance20` float DEFAULT NULL,
  `OperatingNIToTPLatest` float DEFAULT NULL,
  `AssetImpairLossTTM` float DEFAULT NULL,
  `RetainedEarningRatio` float DEFAULT NULL,
  `TotalPaidinCapital` float DEFAULT NULL,
  `Volumn3M` float DEFAULT NULL,
  `OperateProfitTTM` float DEFAULT NULL,
  `NetFinanceCFTTM` float DEFAULT NULL,
  `DividendPS` float DEFAULT NULL,
  `EBIT` float DEFAULT NULL,
  `FCFF` float DEFAULT NULL,
  `Alpha60` float DEFAULT NULL,
  `OperatingRevenuePSLatest` float DEFAULT NULL,
  `DividendPaidRatio` float DEFAULT NULL,
  `ShareholderFCFPS` float DEFAULT NULL,
  `PEG5Y` float DEFAULT NULL,
  `ROECut` float DEFAULT NULL,
  `GrossProfitTTM` float DEFAULT NULL,
  `OperatingRevenueGrowRate5Y` float DEFAULT NULL,
  `NetProfitCashCover` float DEFAULT NULL,
  `EPIBS` float DEFAULT NULL,
  `NLSIZE` float DEFAULT NULL,
  `CmraCNE5` float DEFAULT NULL,
  `STOM` float DEFAULT NULL,
  `IntDebt` float DEFAULT NULL,
  `PEIndu` float DEFAULT NULL,
  `Beta120` float DEFAULT NULL,
  `NIAPCut` float DEFAULT NULL,
  `REVS20Indu1` float DEFAULT NULL,
  `RetainedEarnings` float DEFAULT NULL,
  `Kurtosis60` float DEFAULT NULL,
  `ROECutWeighted` float DEFAULT NULL,
  `RevenueTTM` float DEFAULT NULL,
  `OperCashInToAsset` float DEFAULT NULL,
  `CashEquivalentPS` float DEFAULT NULL,
  `StaticPE` float DEFAULT NULL,
  `REVS5m20` float DEFAULT NULL,
  `GainLossVarianceRatio20` float DEFAULT NULL,
  `NPParentCompanyCutYOY` float DEFAULT NULL,
  `PCFIndu` float DEFAULT NULL,
  `SharpeRatio120` float DEFAULT NULL,
  `NetTangibleAssets` float DEFAULT NULL,
  `IntCL` float DEFAULT NULL,
  `TreynorRatio20` float DEFAULT NULL,
  `DA` float DEFAULT NULL,
  `OperatingRevenuePS` float DEFAULT NULL,
  `InterestCover` float DEFAULT NULL,
  `SalesServiceCashToORLatest` float DEFAULT NULL,
  `ValueChgProfit` float DEFAULT NULL,
  `InformationRatio120` float DEFAULT NULL,
  `EBITDA` float DEFAULT NULL,
  `Kurtosis20` float DEFAULT NULL,
  `OperatingProfitPSLatest` float DEFAULT NULL,
  `NetCashFlowGrowRate` float DEFAULT NULL,
  `REVS750` float DEFAULT NULL,
  `PBIndu` float DEFAULT NULL,
  `TotalAssets` float DEFAULT NULL,
  `NetNonOIToTP` float DEFAULT NULL,
  `MktValue` float DEFAULT NULL,
  `ROIC` float DEFAULT NULL,
  `InteBearDebtToTotalCapital` float DEFAULT NULL,
  `OperatingProfitPS` float DEFAULT NULL,
  `REVS60` float DEFAULT NULL,
  `IntFreeNCL` float DEFAULT NULL,
  `EPSTTM` float DEFAULT NULL,
  `ROEAvg` float DEFAULT NULL,
  `SharpeRatio60` float DEFAULT NULL,
  `InformationRatio20` float DEFAULT NULL,
  `LossVariance120` float DEFAULT NULL,
  `DebtTangibleEquityRatio` float DEFAULT NULL,
  `TSEPToInterestBearDebt` float DEFAULT NULL,
  `PEHist60` float DEFAULT NULL,
  `Alpha120` float DEFAULT NULL,
  `NetProfitGrowRate3Y` float DEFAULT NULL,
  `HsigmaCNE5` float DEFAULT NULL,
  `NRProfitLoss` float DEFAULT NULL,
  `Variance120` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8
/*!50100 PARTITION BY KEY (ticker)
PARTITIONS 50 */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_pettm`
--

DROP TABLE IF EXISTS `yq_pettm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_pettm` (
  `ticker` varchar(12) NOT NULL,
  `tradedate` date NOT NULL,
  `PE` double DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradedate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_s19factors`
--

DROP TABLE IF EXISTS `yq_s19factors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_s19factors` (
  `ticker` varchar(6) NOT NULL,
  `tradeDate` date NOT NULL,
  `PS` float DEFAULT NULL,
  `PCF` float DEFAULT NULL,
  `NetProfitGrowRate` float DEFAULT NULL,
  `GrossIncomeRatio` float DEFAULT NULL,
  `EquityToAsset` float DEFAULT NULL,
  `BLEV` float DEFAULT NULL,
  `CashToCurrentLiability` float DEFAULT NULL,
  `CurrentRatio` float DEFAULT NULL,
  `Skewness` float DEFAULT NULL,
  PRIMARY KEY (`ticker`,`tradeDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_sechaltget`
--

DROP TABLE IF EXISTS `yq_sechaltget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_sechaltget` (
  `secID` text,
  `haltBeginTime` datetime DEFAULT NULL,
  `haltEndTime` datetime DEFAULT NULL,
  `ticker` text,
  `secShortName` text,
  `exchangeCD` text,
  `listStatusCD` text,
  `delistDate` text,
  `assetClass` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_secidget`
--

DROP TABLE IF EXISTS `yq_secidget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_secidget` (
  `replace` bigint(20) DEFAULT NULL,
  `secID` text,
  `ticker` text,
  `secShortName` text,
  `cnSpell` text,
  `exchangeCD` text,
  `assetClass` text,
  `listStatusCD` text,
  `listDate` date DEFAULT NULL,
  `transCurrCD` text,
  `ISIN` text,
  `partyID` double DEFAULT NULL,
  KEY `ix_yq_SecIDGet_replace` (`replace`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_secstget`
--

DROP TABLE IF EXISTS `yq_secstget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_secstget` (
  `tradeDate` date DEFAULT NULL,
  `secID` varchar(20) DEFAULT NULL,
  `ticker` varchar(20) DEFAULT NULL,
  `exchangeCD` varchar(10) DEFAULT NULL,
  `tradeAbbrName` varchar(20) DEFAULT NULL,
  `STflg` varchar(6) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_socialdatagubaget`
--

DROP TABLE IF EXISTS `yq_socialdatagubaget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_socialdatagubaget` (
  `ticker` varchar(12) NOT NULL,
  `statisticsDate` date NOT NULL,
  `postNum` int(11) DEFAULT NULL,
  `postPercent` float DEFAULT NULL,
  `insertTime` datetime DEFAULT NULL,
  `updateTime` datetime DEFAULT NULL,
  PRIMARY KEY (`ticker`,`statisticsDate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_stop_run_data`
--

DROP TABLE IF EXISTS `yq_stop_run_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_stop_run_data` (
  `secID` text,
  `haltBeginTime` text,
  `haltEndTime` text,
  `symbol` text,
  `secShortName` text,
  `exchangeCD` text,
  `listStatusCD` text,
  `delistDate` text,
  `assetClass` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_tradingdate`
--

DROP TABLE IF EXISTS `yq_tradingdate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_tradingdate` (
  `tradingdate` date NOT NULL,
  PRIMARY KEY (`tradingdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yq_tradingdate_future`
--

DROP TABLE IF EXISTS `yq_tradingdate_future`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yq_tradingdate_future` (
  `tradingdate` date NOT NULL,
  PRIMARY KEY (`tradingdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `yuqer_cal`
--

DROP TABLE IF EXISTS `yuqer_cal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `yuqer_cal` (
  `exchangeCD` text,
  `calendarDate` date DEFAULT NULL,
  `isOpen` bigint(20) DEFAULT NULL,
  `prevTradeDate` date DEFAULT NULL,
  `isWeekEnd` bigint(20) DEFAULT NULL,
  `isMonthEnd` bigint(20) DEFAULT NULL,
  `isQuarterEnd` bigint(20) DEFAULT NULL,
  `isYearEnd` bigint(20) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-09-14 21:48:49
