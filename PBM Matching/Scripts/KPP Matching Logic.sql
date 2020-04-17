USE [ODS]
GO
/****** Object:  StoredProcedure [KPP].[KPPClaimMatching]    Script Date: 4/13/2020 9:04:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------
-- Matches imported claims to the LuminX claims in the EDW.
--
-- by Jed Proujansky
---------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [KPP].[KPPClaimMatching] AS

-----------FULL MATCH-----------------------------
	update KPP.Claim
	set LXContractID = 0, LXClaimID = 0, LXDependentID = 0, LXGroupID = 0 , PCPStartDate =''
	from KPP.Claim
	--join LandingZone.PBM.PBMReference on PBMReferenceFK = PBMReferencePK
	--where TPAName = 'Healthcomp'  --37088

	update KPP.Claim
	set LXContractid = clpartic, LXDependentID = cldepno, lxgroupid = clgroup,
		lxclaimid = clyear + clmonth + clday + claclmno , PCPStartDate = '1'
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
	where [ClaimStatusCode] <> '2'
	and insuredNumber = clpartic     
	and DateOfService = CLdateFr  
	and ((TransactionID like '%' + ECatmdls + '%'	and ECatmdls <> '')
		or
		( transactionid like '%' + CLRXNUMB + '%' and CLRXNUMB <> ''	))
	and claimpaidamount = CLTOTPAY
	and clindexi = 'lxcvrxld'------18998

----------------------new
update KPP.Claim
	set LXContractid = clpartic, LXDependentID = cldepno, lxgroupid = clgroup,
		lxclaimid = clyear + clmonth + clday + claclmno , PCPStartDate = '2'
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
	where lxclaimid = '0'  
	and [ClaimStatusCode] <> '2'
	and insuredNumber = clpartic     
	and DateOfService = CLdateFr  
	and TransactionID like '%' + ECatmdls + '%'
	--and ECatmdls <> ''
	and claimpaidamount = CLTOTPAY ----133151
	and totalcost = clcharge and ClaimStatusCode = '1'
	--and clyear + clmonth + clday + claclmno not in (select lxclaimid from kpp.claim)
	



-------------------- |Member Matching on participant ID


	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = '3'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		LXContractid is null
		or LXContractid = '0'
	)
	and InsuredNumber <> ''
	and insuredNumber = gppartic
	and DateOfService between PEFROMDT and petodate ---262515
------------------------------------------------Member Matching on Participant ID, removing trailing zeros
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = '4'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		LXContractid is null
		or LXContractid = '0'
	)
	and InsuredNumber <> ''
	and left(insuredNumber, 7) = gppartic
	and DateOfService between PEFROMDT and petodate ----------44616
------------------------------------------
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = '5'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		LXContractid is null
		or LXContractid = '0'
	)
	and InsuredNumber <> ''
	and InsuredMemberNumber = gppartic
	and DateOfService between PEFROMDT and petodate---21
------------------------------------------------------
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = '6'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		LXContractid is null
		or LXContractid = '0'
	)
	and
	(
		lxcontractid is null
		or lxcontractid = '0'
	)
	and InsuredNumber <> ''
	and insuredNumber = gpssn
	and DateOfService between PEFROMDT and petodate--0
-----------------------------------------------------------------	
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = '7'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		LXContractid is null
		or LXContractid = '0'
	)
	and InsuredNumber <> ''
	and insuredNumber = gppartic--4630
	---------------------------------------------
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = '8'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		lxcontractid is null
		or lxcontractid = '0'
	)
	and InsuredNumber <> ''
	and InsuredMemberNumber = gppartic--6
	---------------------------------
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0', PCPStartDate = '9'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		lxcontractid is null
		or lxcontractid = '0'
	)
	and InsuredNumber <> ''
	and left(InsuredMemberNumber, 7) = gppartic---------44300
	------------------------------------------------------
	update ods.kpp.claim
	set LXContractid = gppartic, LXDependentID = '00', lxgroupid = gpgroup, lxclaimid = '0' , PCPStartDate = 'A'
	from chp_dw_landingzone.dbo.particip
	join chp_dw_landingzone.dbo.partcovg on gpgroup = pegroup
										 and gppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where
	(
		LXContractid is null
		or LXContractid = '0'
	)
	and
	(
		lxcontractid is null
		or lxcontractid = '0'
	)
	and InsuredNumber <> ''
	and insuredNumber = gpssn---0

	---------------------Dependent matchingon participant ID



	update ods.kpp.claim
	set LXContractid = dppartic, LXDependentID = DPDEP, lxgroupid = dpgroup,  PCPStartDate = 'B'
	from chp_dw_landingzone.dbo.DEPENDNT
	join chp_dw_landingzone.dbo.partcovg on dpgroup = pegroup
										 and dppartic = pepartic
										 and
										 (
											substring(pegroup, 7, 2) <> 'AC'
											or pegroup = 'ST0148AC'
										 )
	where 
	 FirstName = dpfirst
	 and DateofBirth = dpdob
	and InsuredNumber <> ''
	and insuredNumber = dppartic
	and DateOfService between PEFROMDT and petodate ---0
	--------------------------------------------------------------------
	
	--------------------------------------------Added by JP toimprove group matching  11/05/2019-----------------------------
	update kpp.Claim
	set LXGroupID = CHPGroupid                         , PCPStartDate = ltrim(rtrim(PCPStartDate)) +'C'
	from Gemini.GroupInfo.dbo.ViewFileFeed_PBMInfoTbl
	where
	(
		LXClaimID = '0'
		or LXClaimID is null
	)
	and [ClientHQCode] = pbmnumber
	and DateofService between planeffectivedate and plantermdate
	and pbm like 'kroger%'
	and left(chpgroupid,2)  <> 'is'--------314690
	-------------------------------------------------------

	update KPP.Claim
	set LXGroupID = '0'
	where LXGroupID is null

	update KPP.Claim
	set LXContractID = '0'
	where LXContractID is null

	update KPP.Claim
	set LXDependentID = '0'
	where LXDependentID is null

	update KPP.Claim
	set LXClaimID = '0'
	where LXClaimID is null
RETURN 0