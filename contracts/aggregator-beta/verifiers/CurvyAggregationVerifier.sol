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
    uint256 constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax = 17922522738663902115117377377982546569645589916258781359614940213559521337740;
    uint256 constant alphay = 14740734263217839637573120881664842776356816571424970874575900781164523221181;
    uint256 constant betax1 = 5278873427941912624128889387859266618662347225180333328912288126360251507135;
    uint256 constant betax2 = 917272575500959667900521150316536678534830131103465904787680477675371433178;
    uint256 constant betay1 = 14527940352733074586905800962684936118698189610065003659367554377272063336553;
    uint256 constant betay2 = 3012380218700810341236716024685650720895952020775664922684381318641806519826;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 20222339171109433566095637911221139079198415388221126284034696647139175763733;
    uint256 constant deltax2 = 19702364068152807372467034526796074340124002601249127084238279592231770147764;
    uint256 constant deltay1 = 17934523538851032518149671992249975043549759635450878406861536463586175119455;
    uint256 constant deltay2 = 5781447621356417190275152851077844414996598878139821491476736373506705071165;

    uint256 constant IC0x = 898153385073310275883601226959348908550589371529824396838107053834994537024;
    uint256 constant IC0y = 11180000966216436871252911415607736223481966214415189919615879668647219178794;

    uint256 constant IC1x = 5970789146253953582395972247397243793615432172373556188666914160775035785231;
    uint256 constant IC1y = 16246652510753311480353110847982724610166807394618798828917415513387980452604;

    uint256 constant IC2x = 21712882084351938943584291857651202245651837291689190836689721228720161951961;
    uint256 constant IC2y = 594014594567249229404018026814771147191245997095031974099492768853052137543;

    uint256 constant IC3x = 14353870467220054878079788576840319875597136464546605928631759372150716746154;
    uint256 constant IC3y = 5464846239289946959681193826367932059433426085030956349396363024530194793093;

    uint256 constant IC4x = 5471182002455055135343437473433097061185558841765312979142644524348131792733;
    uint256 constant IC4y = 7128212485125906080884669597463729681011672481882602265285727860752713863171;

    uint256 constant IC5x = 6629996653933356611257911976465689333197741308650357423553455309388388009772;
    uint256 constant IC5y = 6369106729164974684251756483343970844187820745612551460430383194639419063113;

    uint256 constant IC6x = 10983039400041843205954171843710981670766642663054920072446822113743180811870;
    uint256 constant IC6y = 9067533021597626430588849732858478654537675499043444178580317085486720817672;

    uint256 constant IC7x = 10511439214842938765948685543594836722974458318636361191205933566790524562283;
    uint256 constant IC7y = 20777523055157086665592725098180766433178984409950536537754116189559021735703;

    uint256 constant IC8x = 20485023888358217129233317942740092319737184981681848223872177059552246125887;
    uint256 constant IC8y = 21520170260859049131011449254417729687930817700605258875786137234998714620857;

    uint256 constant IC9x = 6444586407202820948528642989869689256981793023216927536623061926214174876655;
    uint256 constant IC9y = 14969335748793917194570690024709225702693279585884096028697922917077757036015;

    uint256 constant IC10x = 17135114531161188938218566028944914495229268335292838939586491392864342311917;
    uint256 constant IC10y = 8292611074047163119338490159238611909599582124530159810669093276645175239980;

    uint256 constant IC11x = 20958450594482625467234382508711431365090309488926405469310606136771291328457;
    uint256 constant IC11y = 1819386414581578137036403632208149741851901088710434760355562174262876416729;

    uint256 constant IC12x = 5015754084058860115806880003760026301078603233582653337764325871591645490589;
    uint256 constant IC12y = 12063064065729052349636672618879944451735420388817052926534501552646939432863;

    uint256 constant IC13x = 14278692522945533939049609779920525894316966522033894882034029398377040992500;
    uint256 constant IC13y = 21537029149892198871806194136700545760540270161914303544288190286854853268598;

    uint256 constant IC14x = 8852940436328877578256982015494558243010525830716985870625408341728468839437;
    uint256 constant IC14y = 20851237685017606851387650512439869290205446571842448019334229396591909277260;

    uint256 constant IC15x = 5039397919082151200630662536126262134082552176346639914582343658836469029166;
    uint256 constant IC15y = 7860524517970671584526204894711046187862941167097162207691306088309509824874;

    uint256 constant IC16x = 21249243044984654748576200140035857364129871461216490540695964520450245043317;
    uint256 constant IC16y = 3653160210214312881505679521536536382033381325789464490799555506706439382047;

    uint256 constant IC17x = 4923738281157037174612114945717990413988716912099255441070283953274232975178;
    uint256 constant IC17y = 7179121970514419263964373942577453848007099851800511866727533344652238149318;

    uint256 constant IC18x = 7521769617715676938694896374743547395595109969228232912673908954275938138036;
    uint256 constant IC18y = 1950353889497763016111151441345473437837403521151608370807435703007781204664;

    uint256 constant IC19x = 2131107683967139305296355376579984239672349579766847477359541495310321856371;
    uint256 constant IC19y = 4545458171157024445834691227148744001197933688055736012268368941231752325952;

    uint256 constant IC20x = 1127246881403017359437587175407862228427929012539058435878795087501249235957;
    uint256 constant IC20y = 18377398291480315008948421119257364934522437722377153967587697036580330557335;

    uint256 constant IC21x = 2815471345515665734681820159127748770545000343290536820992081354498076839208;
    uint256 constant IC21y = 16598090864180783468602068276194986933436065951113823798495471436857015560541;

    uint256 constant IC22x = 3852365207163562840697929367881098188204315625477297371318563113850703637368;
    uint256 constant IC22y = 20769391906732896344608974308910473007217543829000021933619148898863103990742;

    uint256 constant IC23x = 14526535412534798267101169057210016298028072587272756013234253297737606858574;
    uint256 constant IC23y = 18888272401616675634304036205591611316124075775336645353370826486644729004255;

    uint256 constant IC24x = 14146048344444521033183116259270660747466134583511973638318538211307644768686;
    uint256 constant IC24y = 227399438109887208936106505042776060183359073323409377396669234427734216410;

    uint256 constant IC25x = 14254952072904971838899609626848670759761074350856247009096803698126828271422;
    uint256 constant IC25y = 19692796100551479411962832145121813353295020422328640761629389347226159261424;

    uint256 constant IC26x = 17435378869731216877726179147995752153378148545674771963374311220924005190322;
    uint256 constant IC26y = 4525373028585161597347210361448204582193023446923961929538421810814582328057;

    uint256 constant IC27x = 18427265655020525800887619627255149698156343849035595574397665502453631620399;
    uint256 constant IC27y = 19529417820069958242404334303341221536226322968587287834849625703567280534626;

    uint256 constant IC28x = 2007367606105582341750646721400081951506066288404486206815655265948687328563;
    uint256 constant IC28y = 20548904881794238148909748840488383677024579669366420763788648147812029392475;

    uint256 constant IC29x = 891851336628164343745361497615527805064462752243511738276915364452867786307;
    uint256 constant IC29y = 17446852265679739176401815172838814079948782662690446503128772377983186532949;

    uint256 constant IC30x = 5423643468087828735625347746754187581538303239405795241568780893429085054809;
    uint256 constant IC30y = 19154189975832912594817464860812871829182706623261094339886519799326087975255;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[30] calldata _pubSignals
    ) public view returns (bool) {
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
