USE [ODS]
GO
/****** Object:  StoredProcedure [Optum].[OptumClaimMatching]    Script Date: 9/2/2020 10:03:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------
-- Matches imported claims to the LuminX claims in the EDW.
--
-- by Jed Proujansky

-- 8/13/2020 Jed Proujansky  Added match on charges in query 3 to eliminate mismatching on refund claims
--							Mostly needed for claims that paid 0 and have a 0 refund.
---------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [Optum].[OptumClaimMatching] AS

----  To be uncommented when testing.
update ODS.OPTUM.Claim
	set LXContractID = '0', LXDependentID = '0', LXGroupID = '0',
		LXClaimID = '0'				,SCARRIERID = ''

		
	--#1--------- FULL MATCH--------------Memberid and mbrfamlyid give same results----------------------------
	update ODS.OPTUM.Claim
	set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno					--,SCARRIERID = '1'  -- added for testing
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
	--and cltpatpay = CLCHARGE  -- added 8/12/2020 to eliminate negatives and positives being mismatched
	and clindexi = 'lxcvrxld'
	and CLTINGRCST + CLTDISPFEE + CLTSLSTAX + CLTINCENTV  = clcharge

	

	--#2------------------Full match with SSN replacing contractid --------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno				--	,SCARRIERID = '2'  -- added for testing
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
	--and cltpatpay = CLCHARGE  -- added 8/12/2020 to eliminate negatives and positives being mismatched
	and clindexi = 'lxcvrxld'
	and CLTDUEAMT = clcharge
	
	
	--#3-------------------------------------------------------------------------------------------------------
	update ODS.OPTUM.CLAIM
	set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno 				--	,SCARRIERID = '3'  -- added for testing
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
		CLTINGRCST + CLTDISPFEE + CLTSLSTAX + CLTINCENTV = clcharge
		or cltotpay = CLTDUEAMT
	)
	and cltpatpay -CLTPRODSEL  = CLCHARGE -- added 8/12/2020 to eliminate negatives and positives being mismatched

	----------------------------------#3a eliminating duplicate matches


IF OBJECT_ID('tempdb..#tmp1') IS NOT NULL	
drop table #tmp1;

IF OBJECT_ID('tempdb..#tmp2') IS NOT NULL
drop table #tmp2;


select lxclaimid, min(optumclaimpk) clpk
into #tmp1
from optum.claim 
where CLAIMSTS <> 'R'
group by lxclaimid
having count(*) > 1

select c.lxclaimid, c.optumclaimpk
into #tmp2
from  optum.claim c
	join #tmp1 t
	on t.lxclaimid = c.lxclaimid
where c.OptumClaimPK <> t.clpk and CLAIMSTS <> 'R'
--------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = clpartic, LXDependentID = cldepno, LXGroupID = clgroup,
		LXClaimID = chyear + chmonth + chday + chaclmno					--,SCARRIERID = '5'  -- added for testing
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
	--and cltpatpay = CLCHARGE  -- added 8/12/2020 to eliminate negatives and positives being mismatched
	and clindexi = 'lxcvrxld'
	and CLTINGRCST + CLTDISPFEE + CLTSLSTAX + CLTINCENTV  = clcharge
	and lxclaimid in (select lxclaimid from #tmp2)
	and OptumClaimPK not in (select OptumClaimPK  from #tmp2)



	--#4-------Match without claims using coverge periods------------------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = contractid, LXDependentID = membersuffixcode, LXGroupID = groupid, LXClaimID = '0'
	from CHP_DM_Finance.[dbo].[BridgeMemberEligibilityProduct] bmep
	join CHP_DM_Finance.dbo.factmembereligibility fme on bmep.[FactMemberEligibiltyPK] = fme.[FactMemberEligibiltyPK]
	join CHP_DM_Finance.dbo.dimmember dm on fme.dimmemberpk = dm.dimmemberpk
	where lxclaimid is null
	and mbrfamlyid = dm.contractid
	and dtefilled between coverageeffectivedate and coverageendingdate

	--#4-------Match without claims using coverge periods------------------------------------------------------
	update ODS.OPTUM.Claim
	set LXContractID = contractid, LXDependentID = membersuffixcode, LXGroupID = groupid, LXClaimID = '0'
	from CHP_DM_Finance.[dbo].[BridgeMemberEligibilityProduct] bmep
	join CHP_DM_Finance.dbo.factmembereligibility fme on bmep.[FactMemberEligibiltyPK] = fme.[FactMemberEligibiltyPK]
	join CHP_DM_Finance.dbo.dimmember dm on fme.dimmemberpk = dm.dimmemberpk
	where (lxclaimid is null or lxclaimid = '0')
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
	
	
	drop table #gempbminfo
	
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

--select count(*),    --claims 1,445,379	matched 985,676 original code
--sum(case
--when lxclaimid <> '0'--claims 1,445,379	matched 967,414 coded #3
--then 1 else 0 end)
--from optum.Claim 