USE [ODS]
GO
/****** Object:  StoredProcedure [OPTUM].[OptumClaimMatching]    Script Date: 5/13/2020 8:26:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------
-- Matches imported claims to the LuminX claims in the EDW.
--
-- by Jed Proujansky
---------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [OPTUM].[OptumClaimMatching] AS
	--#1--------- FULL MATCH--------------Memberid and mbrfamlyid give same results----------------------------
	update ODS.OPTUM.Claim
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
	where CLAIMSTS <> 'R'
	and mbrfamlyid = clpartic
	and RXNUMBER like '%' + ECatmdls + '%'
	and ECatmdls <> ''
	and dtefilled = cldatefr
	and cltotpay = CLTDUEAMT
	and clindexi = 'lxcvrxld'
	and CALINGRCST + caldispfee + POSSLSTAX = clcharge

	--#2------------------Full match with SSN replacing contractid --------------------------------------------
	update ODS.OPTUM.Claim
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
	join chp_dw_landingzone.dbo.particip on gppartic = clpartic
										 and gpgroup = CLGROUP
	where CLAIMSTS <> 'R'
	and
	(
		lxclaimid is null
		or LXClaimID = '0'
	)
	and memberid = gpssn
	and RXNUMBER like '%' + ECatmdls + '%'
	and ECatmdls <> ''
	and dtefilled = cldatefr
	and cltotpay = CLTDUEAMT 
	and clindexi = 'lxcvrxld'
	and SBMAMTDUE = clcharge
	and CALINGRCST + caldispfee + POSSLSTAX = clcharge

	--#3-------------------------------------------------------------------------------------------------------
	update ODS.OPTUM.CLAIM
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
	where CLAIMSTS <> 'R'
	and
	(
		lxclaimid is null
		or LXClaimID = '0'
	)
	and mbrfamlyid = clpartic
	and RXNUMBER like '%' + ECatmdls + '%'
	and ECatmdls <> ''
	and dtefilled = cldatefr
	and clindexi = 'lxcvrxld'
	and
	(
		CALINGRCST + caldispfee + POSSLSTAX = clcharge
		or cltotpay = CLTDUEAMT
	)

	--#4-------Match without claims using coverge periods------------------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = contractid, LXDependentID = membersuffixcode, LXGroupID = groupid, LXClaimID = '0'
	from CHP_DM_Finance.[dbo].[BridgeMemberEligibilityProduct] bmep
	join CHP_DM_Finance.dbo.factmembereligibility fme on bmep.[FactMemberEligibiltyPK] = fme.[FactMemberEligibiltyPK]
	join CHP_DM_Finance.dbo.dimmember dm on fme.dimmemberpk = dm.dimmemberpk
	where lxclaimid is null
	and mbrfamlyid = dm.contractid
	and dtefilled between coverageeffectivedate and coverageendingdate

	--#5-----------------------------USING SSN and coverage period---------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = contractid, LXDependentID = membersuffixcode, LXGroupID = groupid, LXClaimID = '0'
	from CHP_DM_Finance.[dbo].[BridgeMemberEligibilityProduct] bmep
	join CHP_DM_Finance.dbo.factmembereligibility fme on bmep.[FactMemberEligibiltyPK] = fme.[FactMemberEligibiltyPK]
	join CHP_DM_Finance.dbo.dimmember dm on fme.dimmemberpk = dm.dimmemberpk
	where memberid <> ''
	and
	(
		lxclaimid is null
		or LXClaimID = '0'
	)
	and memberid = dm.SSNTxt
	and dtefilled between coverageeffectivedate and coverageendingdate

	--#6A----------- Matching without coverage period----------------------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where left(ltrim(rtrim(mbrfamlyid)) + '0000', 7) = gppartic
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where mbrfamlyid <> ''
	and
	(
		lxclaimid is null
		or LXClaimID = '0'
	)
	and left(ltrim(rtrim(mbrfamlyid)) + '0000', 7) = gppartic
	and gpgroup in
	(
		select chpgroupid
		from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl
		where ACCOUNTID = pbmnumber
		and dtefilled between planeffectivedate and plantermdate
	)

	--#6B-------------- Matching without coverage period and without addng zeros-------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where mbrfamlyid = gppartic
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where mbrfamlyid <> ''
	and
	(
		LXContractID is null
		or LXContractID = '0'
	)
	and mbrfamlyid = gppartic
	and gpgroup in
	(
		select chpgroupid
		from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl
		where ACCOUNTID = pbmnumber
		and dtefilled between planeffectivedate and plantermdate
	)

	--#6C-------------- Matching without coverage period and without addng zeros-------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where left(CARDHOLDER, len(ltrim(rtrim(mbrfamlyid))) - 3) = gppartic
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where mbrfamlyid <> ''
	and
	(
		LXContractID is null
		or LXContractID = '0'
	)
	and left(CARDHOLDER, len(ltrim(rtrim(mbrfamlyid))) - 3) = gppartic
	and gpgroup in
	(
		select chpgroupid
		from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl
		where ACCOUNTID = pbmnumber
		and dtefilled between planeffectivedate and plantermdate
	)

	--#6D-------------- Matching without coverage period-------------------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where left(MEMBERID, len(ltrim(rtrim(MEMBERID))) - 3) = gppartic
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where mbrfamlyid <> ''
	and
	(
		LXContractID is null
		or LXContractID = '0'
	)
	and left(MEMBERID, len(ltrim(rtrim(MEMBERID))) - 3) = gppartic
	and gpgroup in
	(
		select chpgroupid
		from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl
		where ACCOUNTID = pbmnumber
		and dtefilled between planeffectivedate and plantermdate
	)

	--#7-----------------Matching on SSN without claim or coverage---------------------------------------------
	select chpgroupid, planeffectivedate, plantermdate, pbmnumber, pbm
	into #gempbminfo
	from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl

	update ODS.OPTUM.Claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where gpssn = memberid
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where
	(
		lxclaimid is null
		or LXClaimID = '0'
	)
	and left(gpgroup, 1) not in ('B', 'F', 'D', 'X')
	and
	(
		len(ltrim(rtrim(memberid))) > 5
		or len(ltrim(rtrim(mbrfamlyid))) > 5
	)
	and case when mbrfamlyid = '' then ltrim(rtrim(memberid)) else ltrim(rtrim(MBRFAMLYID)) end = gpssn
	and gpgroup in
	(
		select chpgroupid
		from #gempbminfo
		where ACCOUNTID = pbmnumber
		and dtefilled between planeffectivedate and plantermdate
	)

	-----#8------- matching for older goroups not in PBMInfoTbl
	update ODS.OPTUM.Claim
	set LXContractID = gppartic, LXDependentID = '00', LXGroupID =
		(
			select max(gpgroup)
			from CHP_DW_LandingZone.dbo.particip
			where left(MEMBERID, len(ltrim(rtrim(MEMBERID))) - 3) = gppartic
			and right(gpgroup, 2) not in ('MR', 'IC', 'AC')
			and gpgroup not in
			(
				select chpgroupid
				from #gempbminfo
			)
		), LXClaimID = '0'
	from CHP_DW_LandingZone.dbo.particip
	where mbrfamlyid <> ''
	and
	(
		LXContractID is null
		or LXContractID = '0'
	)
	and left(MEMBERID, len(ltrim(rtrim(MEMBERID))) - 3) = gppartic

	--#9-------------------------------added 11/5/2019 to match against the PBM info table for group IDs-------
	update optum.Claim
	set LXGroupID = CHPGroupid
	from #gempbminfo
	where
	(
		LXClaimID = '0'
		or LXClaimID is null
	)
	and ACCOUNTID = pbmnumber
	and pbm like 'optum%'
	and dtefilled between planeffectivedate and plantermdate
	-----------------------------------------------------------------------------------------------------------

	update Optum.Claim
	set LXGroupID = '0'
	where LXGroupID is null

	update Optum.Claim
	set LXContractID = '0'
	where LXContractID is null

	update Optum.Claim
	set LXDependentID = '0'
	where LXDependentID is null

	update Optum.Claim
	set LXClaimID = '0'
	where LXClaimID is null
RETURN 0
