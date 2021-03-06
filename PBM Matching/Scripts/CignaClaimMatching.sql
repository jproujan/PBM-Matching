﻿USE [ODS]
GO
/****** Object:  StoredProcedure [CIGNA].[CignaClaimMatching]    Script Date: 5/13/2020 8:24:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------
-- Matches imported claims to the LuminX claims in the EDW.
--
-- by Jed Proujansky
--
-- 7/15/2019 Jed Proujansky
-- Modified code to do a cltotpay = amount billed and changed the between to only do those that did not match.
-- This was done to improve performance.
-- 7/15 Jed Proujansky
-- changed match to include charges and participant ID or SSN
---------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [CIGNA].[CignaClaimMatching] AS
	update Cigna.Claim
    set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno
    from chp_dw_landingzone.dbo.claimdtl
	join chp_dw_landingzone.dbo.claimhdr on clyear = chyear
										 and clmonth = chmonth
										 and clday = chday
										 and claclmno = chaclmno 
	join chp_dw_landingzone.dbo.claimctl on clyear = cnyear
										 and clmonth = cnmonth
										 and clday = cnday
										 and claclmno = CNACLMNO
										 and clline = CNLINE  
	join CHP_DW_LandingZone.dbo.particip on gppartic = clpartic
										 and gpgroup = clgroup    -- added 7/16/2019 by jed
	where right(ltrim(rtrim(PrescriptionNumber)), 7) = right(ltrim(rtrim(ECatmdls)), 7)
	and datefilled = cldatefr 
	and ingredientcost + dispensingfee = clcharge   -- added 7/16/2019 by jed
	and cltotpay = amountbilled
	and
	(
		left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = clpartic
		or left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = gpssn
		or
		(
			LEFT(GPFIRST, 12) = LEFT(CardholderFirstName, 12)
			AND GPLAST = CardholderLastName
		)
	)  -- added 7/16/2019 by jed


	---------------------------------------------------------------------------------------------------------------------------------------------------------
	update Cigna.Claim
    set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno
    from chp_dw_landingzone.dbo.claimdtl
	join chp_dw_landingzone.dbo.claimhdr on clyear = chyear
										 and clmonth = chmonth
										 and clday = chday
										 and claclmno = chaclmno 
	join chp_dw_landingzone.dbo.claimctl on clyear = cnyear
										 and clmonth = cnmonth
										 and clday = cnday
										 and claclmno = CNACLMNO
										 and clline = CNLINE
	join CHP_DW_LandingZone.dbo.particip on gppartic = clpartic
										 and gpgroup = clgroup 
	where lxclaimid is null
	and right(ltrim(rtrim(PrescriptionNumber)), 7) = right(ltrim(rtrim(ECatmdls)), 7)
	and datefilled = cldatefr
	and ingredientcost + dispensingfee = clcharge   -- added 7/16/2019 by jed
	and cltotpay between amountbilled - 1 and AmountBilled + 1
	and
	(
		left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = clpartic
		or left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = gpssn
		or
		(
			LEFT(GPFIRST, 12) = LEFT(CardholderFirstName, 12)
			AND GPLAST = CardholderLastName
		)
	)

	update ODS.CIGNA.CLAIM
    set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno
    from chp_dw_landingzone.dbo.claimdtl
	join chp_dw_landingzone.dbo.claimhdr on clyear = chyear
										 and clmonth = chmonth
										 and clday = chday
										 and claclmno = chaclmno 
	join chp_dw_landingzone.dbo.claimctl on clyear = cnyear
										 and clmonth = cnmonth
										 and clday = cnday
										 and claclmno = CNACLMNO
										 and clline = CNLINE  
	join CHP_DW_LandingZone.dbo.particip on gppartic = clpartic
										 and gpgroup = clgroup
	where lxclaimid is null
	and right(ltrim(rtrim(PrescriptionNumber)), 7) = right(ltrim(rtrim(ECatmdls)), 7)
	and datefilled = cldatefr 
	and
	(
		ingredientcost + dispensingfee = clcharge
		or cltotpay = amountbilled
	)
	and
	(
		left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = clpartic
		or left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = gpssn
		or
		(
			LEFT(GPFIRST, 12) = LEFT(CardholderFirstName, 12)
			AND GPLAST = CardholderLastName
		)
	)

	----------match without ECatmdls
	update ODS.CIGNA.CLAIM
    set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno
    from chp_dw_landingzone.dbo.claimdtl
	join chp_dw_landingzone.dbo.claimhdr on clyear = chyear
										 and clmonth = chmonth
										 and clday = chday
										 and claclmno = chaclmno 
	join chp_dw_landingzone.dbo.claimctl on clyear = cnyear
										 and clmonth = cnmonth
										 and clday = cnday
										 and claclmno = CNACLMNO
										 and clline = CNLINE  
	join CHP_DW_LandingZone.dbo.particip on gppartic = clpartic
										 and gpgroup = clgroup
	where
	(
		lxclaimid is null
		or lxclaimid = '0'
	)
	and clindexi = 'lxcvrxld'
	and datefilled = cldatefr 
	and
	(
		ingredientcost + dispensingfee = clcharge
		or cltotpay = case when amountbilled = 0.00 then 99999.99 else amountbilled end
	)
	and
	(
		left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = clpartic
		or left(cardholderidnumber, len(ltrim(rtrim(cardholderidnumber))) - 2) = gpssn
		or
		(
			LEFT(GPFIRST, 12) = LEFT(CardholderFirstName, 12)
			AND GPLAST = CardholderLastName
		)
	)
	and CLNDCCOD = ndcnumber

	-----------Match without claims using coverge periods
	update ods.cigna.claim
	set LXContractID = contractid, LXDependentID = membersuffixcode, LXGroupID = groupid, LXClaimID = '0'
	from CHP_DM_Finance.[dbo].[BridgeMemberEligibilityProduct] bmep
	join CHP_DM_Finance.dbo.factmembereligibility fme on bmep.[FactMemberEligibiltyPK] = fme.[FactMemberEligibiltyPK]
	join CHP_DM_Finance.dbo.dimmember dm on fme.dimmemberpk = dm.dimmemberpk
	where lxclaimid is null
	and CardholderIDNumber = rtrim(ltrim(dm.contractid)) + dm.MemberSuffixCode
	and substring(dm.GroupId, 7, 2) = 'sh'
	and DateFilled between coverageeffectivedate and coverageendingdate

	---------------------------------USING SSN and coverage period--------
	update ods.cigna.claim
	set LXContractID = contractid, LXDependentID = membersuffixcode, LXGroupID = groupid, LXClaimID = '0'
	from CHP_DM_Finance.[dbo].[BridgeMemberEligibilityProduct] bmep
	join CHP_DM_Finance.dbo.factmembereligibility fme on bmep.[FactMemberEligibiltyPK] = fme.[FactMemberEligibiltyPK]
	join CHP_DM_Finance.dbo.dimmember dm on fme.dimmemberpk = dm.dimmemberpk
	where lxclaimid is null
	and CardholderIDNumber = ltrim(rtrim(dm.SSNTxt)) + dm.MemberSuffixCode
	and substring(dm.GroupId, 7, 2) = 'sh'
	and DateFilled between coverageeffectivedate and coverageendingdate

	---------------- Matching without coverage period
	update ods.cigna.claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where CardholderIDNumber = ltrim(rtrim(gppartic)) + '00'
			and substring(gpgroup, 7, 2) = 'sh'
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where lxclaimid is null
	and CardholderIDNumber = ltrim(rtrim(gppartic)) + '00'

	---------------------Matching on SSN without claim or coverage
	update ods.cigna.claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where ltrim(rtrim(gpssn)) + '00' = CardholderIDNumber
			and substring(gpgroup, 7, 2) = 'sh'
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where
	(
		lxclaimid is null
		or LXClaimid = '0'
	)
	and left(gpgroup, 1) not in ('B', 'F', 'D', 'X')
	and left(ltrim(rtrim(GPPARTIC)), 1) <> '5'
	AND len(ltrim(rtrim(GPPARTIC))) > 5
	and ltrim(rtrim(CardholderIDNumber)) = gpssn

	------------------Updating Group From PBMInfoTbl
	update cigna.Claim
	set LXGroupID = CHPGroupid
	from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl
	where
	(
		LXClaimID = '0'
		or LXClaimID is null
	)
	and SUBSTRING(subgroup, 4, 7) = pbmnumber
	and pbm like 'CIGNA%'
	and
	(
		lxgroupid is null
		or lxgroupid = '0'
	)
	
	-------------
	update cigna.claim
	set LXGroupID = GPGroup, lxcontractid = GPPARTIC
	from chp_dw_landingzone.dbo.partcovg
	join chp_dw_landingzone.dbo.particip on gpgroup = pegroup
										 and gppartic = pepartic
	where LXGroupID = gpgroup
	and left(gpfirst, 12) = PatientFirstName
	and gplast = PatientLastName
	and gpdob = DateofBirth
	and DateFilled between pefromdt and petodate
	and
	(
		LXContractID = '0'
		or LXContractID is null
	)
	
	-----------New EE matching as of 3/09/2020
	update cigna.claim
	set LXGroupID = GPGroup, lxcontractid = GPPARTIC
	from chp_dw_landingzone.dbo.partcovg
	join chp_dw_landingzone.dbo.particip on gpgroup = pegroup
										 and gppartic = pepartic
	where LXGroupID = gpgroup
	and left(gpfirst, 12)= PatientFirstName
	and gplast = PatientLastName
	and gpdob = DateofBirth
	and
	(
		LXContractID = '0'
		or LXContractID is null
	)
	
	--------------------------------------------------
	update cigna.claim
	set LXGroupID = GPGroup, lxcontractid = GPPARTIC
	from chp_dw_landingzone.dbo.partcovg
	join chp_dw_landingzone.dbo.particip on gpgroup = pegroup
										 and gppartic = pepartic
	where LXGroupID = gpgroup
	and left(gpfirst, 12) = PatientFirstName
	and gplast = PatientLastName
	and
	(
		LXContractID = '0'
		or LXContractID is null
	)
	
	------------------dependent matching---------------------------------------------------------
	update cigna.claim
	set LXGroupID = DPGroup, lxcontractid = DPPARTIC
	from chp_dw_landingzone.dbo.partcovg
	join chp_dw_landingzone.dbo.DEPENDNT on dpgroup = pegroup
										 and dppartic = pepartic
	where LXGroupID = dpgroup
	and left(dpfirst, 12) = PatientFirstName
	and dplast = PatientLastName
	and dpdob = DateofBirth
	and DateFilled between pefromdt and petodate
	and
	(
		LXContractID = '0'
		or LXContractID is null
	)
	and LXClaimID is null
	
	----------------------------------------------------------------------------
	update cigna.claim
	set LXGroupID = DPGroup, lxcontractid = DPPARTIC
	from chp_dw_landingzone.dbo.partcovg
	join chp_dw_landingzone.dbo.DEPENDNT on dpgroup = pegroup
										 and dppartic = pepartic
	where LXGroupID = dpgroup
	and left(dpfirst, 12) = PatientFirstName
	and dplast = PatientLastName
	and dpdob = DateofBirth
	and
	(
		LXContractID = '0'
		or LXContractID is null
	)
	and right(CardholderIDNumber, 2) <> '00'
	and LXClaimID is null
	
	----------------------------------------------------------------------------
	update Cigna.Claim
	set LXGroupID = '0'
	where LXGroupID is null

	update Cigna.Claim
	set LXContractID = '0'
	where LXContractID is null

	update Cigna.Claim
	set LXDependentID = '0'
	where LXDependentID is null

	update Cigna.Claim
	set LXClaimID = '0'
	where LXClaimID is null
RETURN 0
