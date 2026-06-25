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
    uint256 constant deltax1 = 750850096521438120913219979964009282040867531380413320675871656578296362920;
    uint256 constant deltax2 = 195712495976797085496709464691991717996553522040276016125421388957828538077;
    uint256 constant deltay1 = 10548759402864141586953786637439732486141619559356621957976297775715129603032;
    uint256 constant deltay2 = 21763829039254339997412756099238072166740329224659265102565711489461306776766;

    
    uint256 constant IC0x = 207570146929169527942857742162667698202250260945567553663098643616010367510;
    uint256 constant IC0y = 18293204616116118861719028381693060408278587829052220643411299807778672029347;
    
    uint256 constant IC1x = 13069158414876417070758084662124004022817551324165050707915742991331344548986;
    uint256 constant IC1y = 16576830727709755584506041453462288349013334926702397172922911143527449063094;
    
    uint256 constant IC2x = 16732786776545931919576682395537106104481231657620455326543429755535759519075;
    uint256 constant IC2y = 11739864499911176616747758068394957978222950577835936209563707203509559291275;
    
    uint256 constant IC3x = 20301923992313249427757666634619575188625998572633433361609023933955160780595;
    uint256 constant IC3y = 17925353153804573437428965726319556190392954101887841962315865153058145468744;
    
    uint256 constant IC4x = 1240561457261441337223300381297996414488217366784083968768527122253750945389;
    uint256 constant IC4y = 17467032107975766460690642628865057963785502885557654589814630923382605839105;
    
    uint256 constant IC5x = 18961412209307928599778843441275519869627434660071695386213707607886444605791;
    uint256 constant IC5y = 12349735948598232123108622054495897580288085804155974852797867061669294486450;
    
    uint256 constant IC6x = 10933655223564516881245120805010019136682667565529938620393937804164199348338;
    uint256 constant IC6y = 21096952098389223911784596648875278597429377204481882989713172996030743147319;
    
    uint256 constant IC7x = 3017360348737026705477596581391687613245433948005751502002992442005033543413;
    uint256 constant IC7y = 20589927645474740509098917009291464635003220102907850674893985008658994836706;
    
    uint256 constant IC8x = 5499870124523257016288351717998054029176495874053000691718213335799820947199;
    uint256 constant IC8y = 3700724942724180798039785448919376783547992592882963048380598180809112242088;
    
    uint256 constant IC9x = 18476104818468784979143384336028797800685715812627106411244279845789472245960;
    uint256 constant IC9y = 3723570344120618804470228934843413486463482330877166431124604855280671053430;
    
    uint256 constant IC10x = 9428704351796018474731809619380356319827140397217814425216401872288235021698;
    uint256 constant IC10y = 11637091216765123185014668260145071738697455891695209308502953648533289384330;
    
    uint256 constant IC11x = 14029684818449864644786707134442992024628390894683499041008729592905735102675;
    uint256 constant IC11y = 13914459602912793771829348937258385557846981697596353207890368065834885182056;
    
    uint256 constant IC12x = 6403211894380940141803007098689448493951097799610249808866022098567597749099;
    uint256 constant IC12y = 1410308921255638971155929809277831462012677527325267250655903591303764774784;
    
    uint256 constant IC13x = 11015077557458108143152678854159008766005112594282008030264169156121937638510;
    uint256 constant IC13y = 4779053204920406480843610692827418692896101799897485541951781133543712591574;
    
    uint256 constant IC14x = 1628301447602326542157415113847737122442898007598150379516543561725549551584;
    uint256 constant IC14y = 19977054429244033853609861225831753712021209153232144681350389759469212578700;
    
    uint256 constant IC15x = 20973910085039654030695225035514495233597857769242747441178554494104560485033;
    uint256 constant IC15y = 1724672257027479996060863050814907115503281323781326419328943844310943934375;
    
    uint256 constant IC16x = 21251812176051506873895884421054158498460160302255872592925585576306346145623;
    uint256 constant IC16y = 6021279001598670515130781425521852297804758379805846872752592276709479374008;
    
    uint256 constant IC17x = 21603237097335253823735188426956780416978694364370633717885367872319139135723;
    uint256 constant IC17y = 7632338841119010331656777091719926289899699922201298808528096872662784637829;
    
    uint256 constant IC18x = 5936574865680739501552506340264345145099383251937035269000960959738908072819;
    uint256 constant IC18y = 14741136311184210791247479611815844158260135209023264301997598115156733839625;
    
    uint256 constant IC19x = 2271496180384172092341025232831710998117731330941592864146411841470826923168;
    uint256 constant IC19y = 14389645408653530238101250306906317291274012473714057214818889076581128207698;
    
    uint256 constant IC20x = 18183306318509091343197648192468539623986058060895847977523948071463562405671;
    uint256 constant IC20y = 20500302795554897550991298510005473106520563676301726037255909381914004295957;
    
    uint256 constant IC21x = 3615910837272796163442022724304491824020233328801945420621905006351479999494;
    uint256 constant IC21y = 780503232423426014312523843827815849905200992814748750449067689535589779380;
    
    uint256 constant IC22x = 13006248720120050678876435620273944758883327662878527582812259197421302315008;
    uint256 constant IC22y = 1864401976735028908315968499370135719062564337993821809708160979828492555639;
    
    uint256 constant IC23x = 20418274536519196657663090351012713229740736723107240315555536165193791366104;
    uint256 constant IC23y = 12564288327858624190324170312007198674525793535805440145051554299432263902284;
    
    uint256 constant IC24x = 4718062437452485843841335745658556168494523135761664313707782295828361661848;
    uint256 constant IC24y = 19462801928579536577524568472370568984817842949182723471364800654045291291102;
    
    uint256 constant IC25x = 17777799779132119132096808890727165805402865509882310537542191549961975109606;
    uint256 constant IC25y = 21722740752293314107079530640223672192260899433442510535960798429447690452544;
    
    uint256 constant IC26x = 13863311689152531206093085803092376962180716566979588167332022085151347141221;
    uint256 constant IC26y = 9419513748958746782319435442297637856916666563154858488985143250772473414619;
    
    uint256 constant IC27x = 3601952662781853989112321584875543665787672309704783058890342389295689341613;
    uint256 constant IC27y = 11216027149977246602947867212832602272209436823334478007991825811691394298973;
    
    uint256 constant IC28x = 8832740695659341259070095399958500583493574466189283097258057633854747362365;
    uint256 constant IC28y = 1589474127164164624262559915985168987882656938409145038480119946437051307299;
    
    uint256 constant IC29x = 5221455679338316877466346651862712252458428214933850436404555990738044810623;
    uint256 constant IC29y = 585245911925545858261108678643255483980021064163125125953186360682872059298;
    
    uint256 constant IC30x = 13242737343802340504937296471575907650157873591336015985185227160123716666392;
    uint256 constant IC30y = 3409945193747826863144478859867214927243886748856059199520458254498632258944;
    
    uint256 constant IC31x = 10770607117145562572639591010350268650985063993728791290167762681459855060841;
    uint256 constant IC31y = 10939477826332105480371749633736066991388781441569827780016252987612053412028;
    
 
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
