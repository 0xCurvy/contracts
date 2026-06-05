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
    uint256 constant alphax  = 5536961424349605363383079547834611253624935346741365152390207162977808438105;
    uint256 constant alphay  = 13749772433678562890434706129279731963579090160098144777544884938702902460905;
    uint256 constant betax1  = 21539144462070221725621821341946015576120326175803871011603493357885994907466;
    uint256 constant betax2  = 5659603644554161095501694178056314059115677161743536207249127883485320545673;
    uint256 constant betay1  = 4691131688626697606942741238721459887528066028578159700157092274086067572295;
    uint256 constant betay2  = 16115943434355504249774741471862784324432072875945868252002541330617450807010;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 17163589110547457312536061830916127848775814216873666410734101339961557278165;
    uint256 constant deltax2 = 9926618561400609193826074743552585672665587998683598723571557611504277088014;
    uint256 constant deltay1 = 20317360681385435956857532751687195466616292952805676315304074328908197145544;
    uint256 constant deltay2 = 12045742229539276311428622559685165340157699036767251745112188273395764485962;

    
    uint256 constant IC0x = 6164790889437434457719012885321249516293470893064822317955074394911355729458;
    uint256 constant IC0y = 9683932694251030751979385209537373248015177602042261313771199036124445467733;
    
    uint256 constant IC1x = 12384475889991879096836087286310090391899445709404637463063271937861119189817;
    uint256 constant IC1y = 7555646050318421859618533021307559030370201101934882165971261830757599561754;
    
    uint256 constant IC2x = 6136248047731705161219872201405157125185313393502777608225024414811669971005;
    uint256 constant IC2y = 12320419418967920240938685347893352567443578004334583125312738941174606429225;
    
    uint256 constant IC3x = 5293797446106289052105846975083467151422587625085468931948425773665836758242;
    uint256 constant IC3y = 11617441507304075181140919281147097406656493679727076345045818342964471463896;
    
    uint256 constant IC4x = 8014869509095572684445611754369040251563464065264219617419105347550099189742;
    uint256 constant IC4y = 13648180472958942063202215226934140656214334973432363320195468895931660000891;
    
    uint256 constant IC5x = 3452181032060131601543304758586459804624233337854090151285945990598361244416;
    uint256 constant IC5y = 19802079982257872460840128434941138436560905018788689707563181919063828331236;
    
    uint256 constant IC6x = 19324685818430713327276774687140940301275925707057629867041197511583935299324;
    uint256 constant IC6y = 552803918037122023118508786749002887028378667488884865926218662804383900870;
    
    uint256 constant IC7x = 11718096583928157325012864014949005125595724532873671366794805051041611399638;
    uint256 constant IC7y = 14038965303650280011658640744746886923750793553409800192887014820990497864169;
    
    uint256 constant IC8x = 8182086639814644924693604164339455000511436801634122941112785673719269361853;
    uint256 constant IC8y = 3624115454703608404938792411169636294821706642372995547687406510755999210083;
    
    uint256 constant IC9x = 5759475135609239610405316458704078579519326135208610144596019523706699302445;
    uint256 constant IC9y = 12390825186997076752512597095656721268717313828456221444272555606636950919767;
    
    uint256 constant IC10x = 20215299746311732505276495200028059982986390202842468518070775495017502237542;
    uint256 constant IC10y = 7448436436504617636668073622946823018737752413888673490247341128210436596736;
    
    uint256 constant IC11x = 6768894315275182994055161461299815542920015734173808891909954640521779079773;
    uint256 constant IC11y = 10332497541890440284559725395513229702276004353970262216925282841550899103958;
    
    uint256 constant IC12x = 15010792300978793457704090706970971883245702809236047840037028265167427779478;
    uint256 constant IC12y = 68627789993025055328634732359495451066328447720855361815939632360896940617;
    
    uint256 constant IC13x = 5386898917318653246439040247334871632298156277266849143751576187453378853558;
    uint256 constant IC13y = 9328037663639537435327393688442686206543792006684749695372711842951218163885;
    
    uint256 constant IC14x = 2732358758187467761392282695773206081828117915502957111890959878558614543994;
    uint256 constant IC14y = 7553661114419019110936141061995572199641342460858096884944203407830285193525;
    
    uint256 constant IC15x = 12525405205681391513153528683229981495783392586574666721165477770473063012944;
    uint256 constant IC15y = 16132401392879678139376744805978133130814206937625911733686402062277789737876;
    
    uint256 constant IC16x = 19403056782067304163229966497310392456509850973734363743593753502940385437074;
    uint256 constant IC16y = 10782462616356705623856206606764323538673155135182300405055367185795022447824;
    
    uint256 constant IC17x = 20624251434290368453435674478985001321728086655684194857839294117952557338994;
    uint256 constant IC17y = 15879016716073858619451775127641067772788319714616482674983443937949902241800;
    
    uint256 constant IC18x = 9923910906138430683966986308048894466290885926941182204318294726538840850445;
    uint256 constant IC18y = 6779852628832895558394187436441308192512009154011073877802607942098438485327;
    
    uint256 constant IC19x = 10774754889891387186103284605384196415887026328937768092461519424543933621844;
    uint256 constant IC19y = 4958500687492377427442063940679540812536395006263282547589412294071000453907;
    
    uint256 constant IC20x = 10032121957348313645269332787486588736859202404272647667881554018383548446409;
    uint256 constant IC20y = 10309415839140452232392045698540033066244080698565067222404397112663497821290;
    
    uint256 constant IC21x = 3419618895101564943624551361080691368860209209061774065831831856958332258404;
    uint256 constant IC21y = 15385338245749019205217386433072806933405334067732099574462840702197649269466;
    
    uint256 constant IC22x = 15119300313133076914109679951117924746651422884142706664226963094547200137182;
    uint256 constant IC22y = 21076780211243910312352023031721078711243202051150577883092976363434648325272;
    
    uint256 constant IC23x = 8424686211986283734978821931959364777307432439690831500793410726511792864853;
    uint256 constant IC23y = 3143729265212179493845721676624429819283541264991295734640019165679171821495;
    
    uint256 constant IC24x = 6249284890805332915619093701687957242438175618694020498286070926013796178033;
    uint256 constant IC24y = 6265482678259593086662532895932376382525696800547715384962634290166299810607;
    
    uint256 constant IC25x = 5124599617630652766880071145765292812782378636595353174578593130426883330715;
    uint256 constant IC25y = 17968971483739497775696746032774524786989433625248646905120386962479721196794;
    
    uint256 constant IC26x = 3926547335715956910571049351067475638888365320489112870248795437909711153863;
    uint256 constant IC26y = 42296588815960065941383461018381756619667361482002192138437117667259274766;
    
    uint256 constant IC27x = 1263956849844854823848075936526611467901994043724941771374134165339040859851;
    uint256 constant IC27y = 3080181853170205568962360948990129905324921567580958434714785019367485492695;
    
    uint256 constant IC28x = 3160423886663767649535669532726438537063607105169465034625276878296077065932;
    uint256 constant IC28y = 14207442237561677718935484029449931409263710104878814948392097595018715509335;
    
    uint256 constant IC29x = 8187490186171326891290230039484823697422816831761414431422544471574039204152;
    uint256 constant IC29y = 17295468181125843554029184772936672228081253306527637150045661463814866778371;
    
    uint256 constant IC30x = 21582861427035493050396314830166343940751146499860295738504295567370555113555;
    uint256 constant IC30y = 19536855448490505428725286419387189806288469146016232670909498947383008186576;
    
    uint256 constant IC31x = 7702371894513203947179545874094413145692204026470182229850692120009246473638;
    uint256 constant IC31y = 3765215200843067408310923519707272266224029677774596223788494179368743286624;
    
    uint256 constant IC32x = 18587994557245328665705848374503295342452867073283210677683499560283597730956;
    uint256 constant IC32y = 17993838110902518697854653374863144543173772202735038127222698678465218990461;
    
    uint256 constant IC33x = 10817071440919659518041149619382536456578247620073574740052835962406482480533;
    uint256 constant IC33y = 10184628611067737759411839903348728291713011338111804265599344922441562059905;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[33] calldata _pubSignals) public view returns (bool) {
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
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
