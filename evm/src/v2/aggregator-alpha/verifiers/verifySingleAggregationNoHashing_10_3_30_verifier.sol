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

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 13609597477422817544806719940578211239660138492812767741570640666225907996628;
    uint256 constant alphay  = 3315096884673693139303582008970220799715870802021815302955257248960229394132;
    uint256 constant betax1  = 20244502790401697640374985581353359627000854646412500262318694555628864857705;
    uint256 constant betax2  = 18009540316062949354047865494362899064185820891461168067970621853171214969025;
    uint256 constant betay1  = 21485324237153900776296822920524193097954549703233921348239585839570605636041;
    uint256 constant betay2  = 18873349741553391434573540024886497503852362769056818998084383144689457732005;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 19850342809044307314512380526356136573169498890318864198662466347684938791761;
    uint256 constant deltax2 = 20134025061067583334512893737595857429955070169314294407408082490775777708909;
    uint256 constant deltay1 = 4905784578530085215012829635541078760610025456759646721974421090331477321090;
    uint256 constant deltay2 = 2514651420669757337673933092460044209194839633129370427926822061521453102332;

    
    uint256 constant IC0x = 13280217465620363921683471659725144884924418459983237299399885289528604667595;
    uint256 constant IC0y = 21639146647123962221571275881300415131177372421837751817608126629529900941591;
    
    uint256 constant IC1x = 12404312720272009519281559698368076327088737234074386096263565159063490012488;
    uint256 constant IC1y = 4977025938625083337883158236534760358764640151369840684255563853493256526995;
    
    uint256 constant IC2x = 14646195796371099642853674511086405925746575437534552927176142477139223884974;
    uint256 constant IC2y = 1244497930927914351242653417370764264228707361448348674298996135113595066977;
    
    uint256 constant IC3x = 7229581355335587443934715256162333513181418094112639256829444206255687702236;
    uint256 constant IC3y = 13620678229518146547346102160085824662922278122649849781449973660708484259657;
    
    uint256 constant IC4x = 21333272486702777614425198315149932492911757033197242618204325307652921431446;
    uint256 constant IC4y = 12172453039453922243119075093841551751374494894627915863024996614832764200785;
    
    uint256 constant IC5x = 14106200213167329550812867245008755447267831896350340427945543485687592320480;
    uint256 constant IC5y = 14427888847644352698008015975704326707187673806643770623715677933062579955507;
    
    uint256 constant IC6x = 17441474467324721292097835462338447767394745575074741057028697989626363721964;
    uint256 constant IC6y = 21470007548571300623635654544844725279231759964204260759506224797402064598155;
    
    uint256 constant IC7x = 4401233967693470575511207457123504312128930021919495104328125022429820373211;
    uint256 constant IC7y = 5775940860050253843595336957142908529869719241223988790461333192709798921143;
    
    uint256 constant IC8x = 15897794206432213070774241751290306610620784711760030161219398717925894546670;
    uint256 constant IC8y = 13775828113701384802670055364507323928054567082499381653431226086278771962647;
    
    uint256 constant IC9x = 5571667755358784788304663482860421857558624920966217828016753220693032080010;
    uint256 constant IC9y = 3921943725309979312746499935141080039704066256502294453843141010775132549401;
    
    uint256 constant IC10x = 6431907623065003512328832934971058974943339401886379650439481132545017886029;
    uint256 constant IC10y = 3533038363117558005706751517440150612779012916993700541622509270608437169985;
    
    uint256 constant IC11x = 7636177427470274649798506731264959693599808664468961091719663919061029675640;
    uint256 constant IC11y = 1542839690999276670465758422596311026934605709628391078099225304202726097624;
    
    uint256 constant IC12x = 4432311039423586602109240512723036746301860847739394482377198898336314889563;
    uint256 constant IC12y = 9218000852954648846223023036038690777667456259768199591042762583791109433276;
    
    uint256 constant IC13x = 19214011150802957512344806027878187151323478979462793857756685452397791755203;
    uint256 constant IC13y = 14520137900294920970034792411216416911469798015192028975787666656082446872298;
    
    uint256 constant IC14x = 4816309183672771850476009198975332366069932522116787685147090882933101838676;
    uint256 constant IC14y = 20129341938611912583452449767460587009814422823954559551763107953865650508007;
    
    uint256 constant IC15x = 20326775149295097275416169546207499392379561601728261237988998153520073255923;
    uint256 constant IC15y = 10258611676815497076432532343815230782205904614511935253337109063750504666442;
    
    uint256 constant IC16x = 19192108857339306521505725549088174972975451588724418366336269883558954133248;
    uint256 constant IC16y = 741827507702463945218704329372426036419008555543006643557089429499317985173;
    
    uint256 constant IC17x = 3314637281685616202611028792441512505117817331044875724109448345622093498241;
    uint256 constant IC17y = 9326356764465704607264776746340583326268414228750777689932553244974810551171;
    
    uint256 constant IC18x = 9998941555045367100847562715068516172252037675222158600044607732450129214316;
    uint256 constant IC18y = 20734511426359690412894026998380176738598193248747733746774104835376687309185;
    
    uint256 constant IC19x = 10711287865055977314303356538647689991414158751072692335621503892825398167247;
    uint256 constant IC19y = 9036511313378957247734362428882371382327239548187133452337380332325602098292;
    
    uint256 constant IC20x = 3646935788518692768205569846235446177447511076629943829419470282229767975121;
    uint256 constant IC20y = 11322236022772210449327245616607688020355854607815836556991623321422996861183;
    
    uint256 constant IC21x = 7464983505575506719133243091058249000484378611916988660913790841683174639350;
    uint256 constant IC21y = 14926947206393909914202946524274525364493572140061083459568671596023162314312;
    
    uint256 constant IC22x = 15356710011932779912204518404037051407670584822853405168895530063979273903949;
    uint256 constant IC22y = 19964241233780331216464827581421730611060077371105344991281685777988320819989;
    
    uint256 constant IC23x = 17270194552827093805710765472269995805044615484687974228661047307959620663298;
    uint256 constant IC23y = 11875338272893629792070248361406162670773042133544825491881795847592632881693;
    
    uint256 constant IC24x = 7443313515956507852129404104973323149868837107650419105835030928530790784158;
    uint256 constant IC24y = 18889685511216800772225124458360797332252290524802331990815818831446342718898;
    
    uint256 constant IC25x = 12698733842012368965765679274497916018489220337596305944456701594991167880564;
    uint256 constant IC25y = 7905262530596671943915939884770797974606131977143498280231081020777494982468;
    
    uint256 constant IC26x = 14347840468481503208926068666495243048658259842208149562131199097589634446161;
    uint256 constant IC26y = 11349011533534336093785914351420637927507694167679670343839159199192520813369;
    
    uint256 constant IC27x = 21477469191908445005012893406661830375929637631495790322804050959852228988433;
    uint256 constant IC27y = 2819008911913626518437605008181543805477524774911720129060441247220837595893;
    
    uint256 constant IC28x = 10273730746739502225532475459924100760419190127616871532767452943005946705803;
    uint256 constant IC28y = 11831766895397499542898210859326619577133063868456187065846873359283045424647;
    
    uint256 constant IC29x = 7281839931964039049540221116256620107331237858489788455364273994290441360399;
    uint256 constant IC29y = 13804992087835823860229686034949021812225890577146562386418700230422313895829;
    
    uint256 constant IC30x = 1566880447320310054113663789623914148908488618577441242018252483124915339407;
    uint256 constant IC30y = 14193748283658147191726496976480046965188214131711506979021606847246853836849;
    
    uint256 constant IC31x = 17618385395901437005012106059570201650596390308529358562474243447006797731634;
    uint256 constant IC31y = 12404003285444961367148644988548078819597737770922768418182269532128566462411;
    
    uint256 constant IC32x = 3150792832586413809507772922462682635145274660512157716889616773941474907275;
    uint256 constant IC32y = 11399882367200507218829826828081512011637971684576914545613066077449735610490;
    
    uint256 constant IC33x = 5027475851964683017701345764306379778797346809782453074365873094574525672111;
    uint256 constant IC33y = 16761283290554405541595620308138611469706176789920819672216203438448561836123;
    
    uint256 constant IC34x = 3315605509793876772215060790098929226245322454526666866027449953423059335390;
    uint256 constant IC34y = 18740700500381857450241347606318422804167178085034843349403764008926138414552;
    
    uint256 constant IC35x = 5307679787045217069211690143816879352317344501864366228113490052578581432917;
    uint256 constant IC35y = 1582231487075743897389182103903536993518394086612453739054455832364267558703;
    
    uint256 constant IC36x = 21534979119825572206293848679356321674556541629285439332243162370578164802325;
    uint256 constant IC36y = 9171671962311498586947861475265668512701720015036904535469068503693124457865;
    
    uint256 constant IC37x = 14367203559112734134650940051516324098486402972261489357409031535250828482194;
    uint256 constant IC37y = 17552888757403384163183830754491266671804934616124875416484001869512810286344;
    
    uint256 constant IC38x = 2400466742836982720461461656592419865699511283181376494249928223704856409914;
    uint256 constant IC38y = 5331223631998753471630692248711916508659290539636026764904276725093486950108;
    
    uint256 constant IC39x = 9442766584659448510505103278536142549542276959746913210142306034285309978683;
    uint256 constant IC39y = 6368502357964405715968410847982643318119025333396782402898038540694807112789;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[39] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))
                
                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))
                
                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))
                
                g1_mulAccC(_pVk, IC35x, IC35y, calldataload(add(pubSignals, 1088)))
                
                g1_mulAccC(_pVk, IC36x, IC36y, calldataload(add(pubSignals, 1120)))
                
                g1_mulAccC(_pVk, IC37x, IC37y, calldataload(add(pubSignals, 1152)))
                
                g1_mulAccC(_pVk, IC38x, IC38y, calldataload(add(pubSignals, 1184)))
                
                g1_mulAccC(_pVk, IC39x, IC39y, calldataload(add(pubSignals, 1216)))
                

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
            
            checkField(calldataload(add(_pubSignals, 992)))
            
            checkField(calldataload(add(_pubSignals, 1024)))
            
            checkField(calldataload(add(_pubSignals, 1056)))
            
            checkField(calldataload(add(_pubSignals, 1088)))
            
            checkField(calldataload(add(_pubSignals, 1120)))
            
            checkField(calldataload(add(_pubSignals, 1152)))
            
            checkField(calldataload(add(_pubSignals, 1184)))
            
            checkField(calldataload(add(_pubSignals, 1216)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
