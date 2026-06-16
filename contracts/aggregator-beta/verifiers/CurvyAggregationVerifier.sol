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
    uint256 constant alphax  = 10836818490634473748810626217656420567497611652829427788816876291655878061880;
    uint256 constant alphay  = 19592557294703635441720550325614868352753510476494830041649519998296273581264;
    uint256 constant betax1  = 2752341048559771983195772862858294317736863257256041710711081910575247422768;
    uint256 constant betax2  = 9826333155562493365212222126579590648800651794940684025275309064976384210080;
    uint256 constant betay1  = 16077258703357503886012982016198935205232932528577536718488856615641627642164;
    uint256 constant betay2  = 3871366386588539348769067597142190409258468194405874387375929962459989586389;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 2021292073692576827118577626466732330945323248403847316720254139655021066013;
    uint256 constant deltax2 = 10430456853410120367525404046708497426394376645541767727164203487173104919677;
    uint256 constant deltay1 = 7938398816930289041176217831948314233609168237668011407447921910372557150470;
    uint256 constant deltay2 = 4023994373859436746664087800625416097405215100174433055735790975592418006553;

    
    uint256 constant IC0x = 8695741932906612874458848959161978523264029571850643248703586087644073894309;
    uint256 constant IC0y = 12102518118175821971482261172789859275239538023815226634267387344416751552881;
    
    uint256 constant IC1x = 16928745934931212586505209790982606730360746145075612578477948716246154708632;
    uint256 constant IC1y = 995077490508633799588719990955270884864123309322273528108909391315050777294;
    
    uint256 constant IC2x = 1052957011329835036172410889491606708900603100836674618707890859883015019491;
    uint256 constant IC2y = 5399846645682135775148516058477946817953369229315139710706788671124847022756;
    
    uint256 constant IC3x = 3664763448530247334659924464143166507789056201482680001420535091210028832163;
    uint256 constant IC3y = 15886323694121952016810901301876350250648982884550520996673154003780461723936;
    
    uint256 constant IC4x = 13828057514034626095850467276020563166093501024270228187564618102955654997513;
    uint256 constant IC4y = 12971272122830481951834614952928420341778634171878094399892069937818798395793;
    
    uint256 constant IC5x = 11316546817900129723107181136127412299558299448338829074619596464922029466304;
    uint256 constant IC5y = 1135820666453511317470812463281264761586058325182561125812908891553890669467;
    
    uint256 constant IC6x = 11080580421835340022762511614818516409110096641742056755297182066812548260033;
    uint256 constant IC6y = 20004848111797873887604302007317288123059181765227014295402714450797519414908;
    
    uint256 constant IC7x = 21110299842408956863973726975277041014254891220657850264252708017009765864042;
    uint256 constant IC7y = 18962686491114153100720861249754891587507928037762353622153433615844356084066;
    
    uint256 constant IC8x = 14256694180817332492893324496632121221115094611834244395408922419935460890015;
    uint256 constant IC8y = 6461039611671909912457422735391935448679048612173547601457643857790869098929;
    
    uint256 constant IC9x = 15854038266400481477806486911220758972621509478499015474555832889969115269977;
    uint256 constant IC9y = 875519649675871763250747506554634501567812462070980237585231397910651680621;
    
    uint256 constant IC10x = 17552060734608760312560007671050167893493023987133795298582762615101423777742;
    uint256 constant IC10y = 14941476678275640330403779926356265520414483255159898980070119482344811512059;
    
    uint256 constant IC11x = 12923974240945893925509231071859521860427593178946542759321889613731838592975;
    uint256 constant IC11y = 18583136335647323232617429794971854638391904411679864257127214396835640761254;
    
    uint256 constant IC12x = 20549858050417961365928386922513035836318300911557239821525531562862407994191;
    uint256 constant IC12y = 13949232398880320777342558757986045445381502320573823093026109833662239336734;
    
    uint256 constant IC13x = 13241601273071657272945728423060454699085505475778829219441230348445631847118;
    uint256 constant IC13y = 3038839186213478347392926327721512782316854698572713382733275840958135623849;
    
    uint256 constant IC14x = 1827201737795035117290124978574755430498742905134619196034685660226893383261;
    uint256 constant IC14y = 1665681195807414329101325591955736229320157094251142610823500413579081614584;
    
    uint256 constant IC15x = 13672784331625010545260520454556346222358307472697251789073829634557591935568;
    uint256 constant IC15y = 18164649509873789514625037824033193017588824530204068325924152915919955195876;
    
    uint256 constant IC16x = 16906719546257398041613079331060611809105879403668016222274417923997215856974;
    uint256 constant IC16y = 14632512864780357391708583743604391374793349996378421293846816861968647118013;
    
    uint256 constant IC17x = 18015274375751420300231871127324136891068221562785564722065124336698586828058;
    uint256 constant IC17y = 10854426029614174119386300049037913539276980379619225142008449969954265697165;
    
    uint256 constant IC18x = 11507259222260500162769316421929506184423655299645202235692992181409750367236;
    uint256 constant IC18y = 16992009478812953487130848534260812554368782148574443547402920911130079079104;
    
    uint256 constant IC19x = 5010479743271034105060439017717407679162674580052137361299966918053833690961;
    uint256 constant IC19y = 9577836480834751266420965316468923282968446464360325669162478890587253703827;
    
    uint256 constant IC20x = 1498611838956318415531456101776043015588867887569807816756645382801548254564;
    uint256 constant IC20y = 6943263303093366196968304616810087917004529560183344688783416756987815517726;
    
    uint256 constant IC21x = 266601124464744121853555587199330868206661429855572421639639376890728535577;
    uint256 constant IC21y = 12929280106453105669844493345977886996361679374766770103838310173451577490930;
    
    uint256 constant IC22x = 21113235099267739172496570891596130560502655926708546615038606081164391728314;
    uint256 constant IC22y = 2253529601376484323582810613680081542499032173683080463214523490513332388823;
    
    uint256 constant IC23x = 6963526451773586298429457618273951976684763061894667863400269265622775498537;
    uint256 constant IC23y = 5070883038700462904123230611732708798345942979533906971546040517898077115046;
    
    uint256 constant IC24x = 1194229159313376412764742578985594296712111166220493891067851422346227479400;
    uint256 constant IC24y = 12497828281556025238993631426035151943604933855199999871567280770095867352795;
    
    uint256 constant IC25x = 7837464355920946920439134582937477663844957189805562352311601152390095912466;
    uint256 constant IC25y = 21732109912004622003140720774456375081429233631696580200851180093395118784359;
    
    uint256 constant IC26x = 11855767992295388845240754294971398469944927085297492945451377267973835763247;
    uint256 constant IC26y = 15483774964601252134596549872227623169676643642865702678048027241245155054229;
    
    uint256 constant IC27x = 12993354315472412574928337774888718684042611167402844961238254506219255663517;
    uint256 constant IC27y = 16657451666326292319132240572038010969741049112088851809835794282958747721880;
    
    uint256 constant IC28x = 11439563261326104108318414751304943350420557557680642072906603332142595580849;
    uint256 constant IC28y = 4518378719232014485077356316163039564484329510216955385826199783240088244006;
    
    uint256 constant IC29x = 10734047528622337187590141221926529470168640896903185456212963226094001823224;
    uint256 constant IC29y = 15098516964069469223107301990551328200319876183560905745134033639005973036998;
    
    uint256 constant IC30x = 1240862417217798569972170219430443697902304784857390250083252343321150708739;
    uint256 constant IC30y = 11694298985778953901261692937066623784689872777836063030510599559887100449184;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[30] calldata _pubSignals) public view returns (bool) {
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
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
