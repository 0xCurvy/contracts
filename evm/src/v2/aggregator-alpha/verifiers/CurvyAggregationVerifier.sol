// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract CurvyAggregationVerifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 17922522738663902115117377377982546569645589916258781359614940213559521337740;
    uint256 constant alphay  = 14740734263217839637573120881664842776356816571424970874575900781164523221181;
    uint256 constant betax1  = 5278873427941912624128889387859266618662347225180333328912288126360251507135;
    uint256 constant betax2  = 917272575500959667900521150316536678534830131103465904787680477675371433178;
    uint256 constant betay1  = 14527940352733074586905800962684936118698189610065003659367554377272063336553;
    uint256 constant betay2  = 3012380218700810341236716024685650720895952020775664922684381318641806519826;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 7232061267274013086017664851623259859913653436759764518579620562359458547087;
    uint256 constant deltax2 = 3324408933630462585533667293382470244829939210813953053506570780879725488854;
    uint256 constant deltay1 = 231424234986867032874237004571408162292205326238907673078851053268436057266;
    uint256 constant deltay2 = 17757769048395237629952360115128749782984578403277248740622361325800828662888;

    
    uint256 constant IC0x = 6987225292084055765965876122357179431230785357536642772883322739429174420919;
    uint256 constant IC0y = 3852060627852949750926783068720642282064593104968773159589874826072763465824;
    
    uint256 constant IC1x = 6804595479951943283822924158303299728508344028325398323788925119096184927895;
    uint256 constant IC1y = 5604485549394504399258184508042361628571940425164509224885004652651255563009;
    
    uint256 constant IC2x = 8980232001062197342647451253581182910754444070249578309733132819330994170321;
    uint256 constant IC2y = 7075773870292277182064314445488175032748595124735690059866854183281098917201;
    
    uint256 constant IC3x = 12093722398421390986401683483932296792530473210637090065015869905237740008595;
    uint256 constant IC3y = 3752697119288962368153569807146702789656530369814561112715553250187576456635;
    
    uint256 constant IC4x = 7044938509404685874734982123920935508995473033443109482838533710356110258108;
    uint256 constant IC4y = 12872814687803421223911105041867381635866724376205179886730857446703061183803;
    
    uint256 constant IC5x = 6759868698719909992819349781244293969707026579056124310848134117231573421036;
    uint256 constant IC5y = 16980932754848668446412287915781939896485332867672438490999859940332934994579;
    
    uint256 constant IC6x = 19369162517940259711587457002142300753929589966301535547766067988776116332764;
    uint256 constant IC6y = 10606473230365465760370610836581645482516463392750652434681535878290990393372;
    
    uint256 constant IC7x = 20876069114751896066757201487426310820890719976695700382166546364641655840018;
    uint256 constant IC7y = 10725680055553574540178130844445040434319513237972997329876429764400539192785;
    
    uint256 constant IC8x = 14767976543648178512669692233243845762540574169048314484842486787688552180318;
    uint256 constant IC8y = 10526511697900075691292158041264777261210469137787281375344483117755533908717;
    
    uint256 constant IC9x = 419591249494428637660737483113438644195267852461913715957793986005239012466;
    uint256 constant IC9y = 16341967871593569415050624696009202328906865639385593054754975135987547652117;
    
    uint256 constant IC10x = 81106267418315191559508580282270393837746220292831427636453411834477177918;
    uint256 constant IC10y = 8703436648649431254426147874131848249283125752756406116868300476493018362053;
    
    uint256 constant IC11x = 3641754454847872436818960773011850468675642784960787466204855494130229771971;
    uint256 constant IC11y = 637260347319710697592298640303769477782215335725670966078794201931895337228;
    
    uint256 constant IC12x = 8055337038518806017669838898625004042885856983435701656520333603212712194944;
    uint256 constant IC12y = 8371465088334521620431606175544532359667474000439038184560532825816414615042;
    
    uint256 constant IC13x = 19379042652904526124945694269980701356849346704652603982809915469122416078871;
    uint256 constant IC13y = 13694360219636086816822423780783908256621242707764933581019160195954055123990;
    
    uint256 constant IC14x = 1302214927156600682901158996234566284531029123585539116019747216318449438201;
    uint256 constant IC14y = 7442727188410305457569111515395375641723790408225024935720805359323522081826;
    
    uint256 constant IC15x = 14445295394924377030914431244550732831509298941081400256069889780176989772799;
    uint256 constant IC15y = 12865821414481771382837963443717243730487329340981867883332064890291596210325;
    
    uint256 constant IC16x = 2388826593705171574680249832759377031894789503560443798571608314526676646593;
    uint256 constant IC16y = 15030233976768341049396876564378715741280205710282410092704267642027496514030;
    
    uint256 constant IC17x = 7223419389437713126719010790522055611149242397472112033063528111328384271779;
    uint256 constant IC17y = 10924568113686482551364477660021579610054002077985610285342645115350278263511;
    
    uint256 constant IC18x = 20765503312044437165849865883116717985565407678530788253824747968194319469311;
    uint256 constant IC18y = 942554403889103753443745837422675082213678763601683306388090497577786082141;
    
    uint256 constant IC19x = 19806180697914585343554511546186985277579177644232118760648020036823094763925;
    uint256 constant IC19y = 16152295523022794937591527937253116845776730097796504970888478549752364534465;
    
    uint256 constant IC20x = 4454860398795154872615154721190935151562144060479054503963960121780324275338;
    uint256 constant IC20y = 90749485653456314695022680436622040170406070468002840639140003310610309328;
    
    uint256 constant IC21x = 11069228981162447338236158474155500638103721765410996451456584181433654080435;
    uint256 constant IC21y = 20750422425387450285290295764139036990718842445465093842928854496211333243219;
    
    uint256 constant IC22x = 2744656707381614681398386085176588586120401540389495104879857410486047626355;
    uint256 constant IC22y = 14757292508114482453308132876537822759269592808308596125030281912646609331970;
    
    uint256 constant IC23x = 4546610019096123852525050475767000813285320788783793388699923521093153378195;
    uint256 constant IC23y = 783971801513693478614193075865589489352418068483114007341445758981934441620;
    
    uint256 constant IC24x = 720768054092799351238034403001527184354880032994800059098957415838647437939;
    uint256 constant IC24y = 9198945709743486079961376744738609084989333739515921595659342022575639251556;
    
    uint256 constant IC25x = 21715758721579519034915523671791221697196426939318955954605414839342492460414;
    uint256 constant IC25y = 5036463397705666329658889169358753083318005755470634149849857120624180974826;
    
    uint256 constant IC26x = 1698269803576119253578509307189973465649544786759777821993515190560073992821;
    uint256 constant IC26y = 20868024708092672659275158770896741373471423479994445523977520891105205724870;
    
    uint256 constant IC27x = 2750116834969882915098953844596151417440538443167626179221189318544661939038;
    uint256 constant IC27y = 20520911739344425846544378083838165437641347359574692900612099818668884439348;
    
    uint256 constant IC28x = 7410029895885559816834038148359936580153008453578538938663114840054964159585;
    uint256 constant IC28y = 11882710167501383811454414405372398613431756963730256268145591172781966543603;
    
    uint256 constant IC29x = 6183582270774602927003003853586629707704618880948382884583425263731777426931;
    uint256 constant IC29y = 19050825400753840557154178240341311329500893373590835161213237864614425307571;
    
    uint256 constant IC30x = 5917297617901109113678256198518864417991090798057201845760794188966819944009;
    uint256 constant IC30y = 14234709771093273392032472333245744005180280915417723367768132236464330687703;
    
    uint256 constant IC31x = 8592560379757705567730537676540174594571060938911365286334030512662767010367;
    uint256 constant IC31y = 13741975089465710527196826508288781995590009644333028490769692453020164952317;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[31] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                
                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))
                
                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))
                
                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))
                
                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))
                
                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))
                
                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))
                
                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))
                
                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))
                
                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))
                
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                
                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))
                
                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))
                
                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))
                
                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))
                
                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))
                
                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))
                
                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            
            checkField(calldataload(add(_pubSignals, 160)))
            
            checkField(calldataload(add(_pubSignals, 192)))
            
            checkField(calldataload(add(_pubSignals, 224)))
            
            checkField(calldataload(add(_pubSignals, 256)))
            
            checkField(calldataload(add(_pubSignals, 288)))
            
            checkField(calldataload(add(_pubSignals, 320)))
            
            checkField(calldataload(add(_pubSignals, 352)))
            
            checkField(calldataload(add(_pubSignals, 384)))
            
            checkField(calldataload(add(_pubSignals, 416)))
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            
            checkField(calldataload(add(_pubSignals, 800)))
            
            checkField(calldataload(add(_pubSignals, 832)))
            
            checkField(calldataload(add(_pubSignals, 864)))
            
            checkField(calldataload(add(_pubSignals, 896)))
            
            checkField(calldataload(add(_pubSignals, 928)))
            
            checkField(calldataload(add(_pubSignals, 960)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
