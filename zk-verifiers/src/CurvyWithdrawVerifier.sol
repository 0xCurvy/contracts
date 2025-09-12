//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract CurvyWithdrawVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            16428432848801857252194528405604668803277877773566238944394625302971855135431,
            16846502678714586896801519656441059708016666274385668027902869494772365009666
        );

        vk.beta2 = Pairing.G2Point(
            [3182164110458002340215786955198810119980427837186618912744689678939861918171,
             16348171800823588416173124589066524623406261996681292662100840445103873053252],
            [4920802715848186258981584729175884379674325733638798907835771393452862684714,
             19687132236965066906216944365591810874384658708175106803089633851114028275753]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [9278680939259972139434893277622422014529857835952377247058916709152000678813,
             18234123392004066380665998174621444502323073192652719109112246062041579475955],
            [1304305336414553409370754830424865815171645804840212792230905450011932315702,
             2434841716894696921746069540510301619482781305522071678461906246192971634300]
        );
        vk.IC = new Pairing.G1Point[](27);
        
        vk.IC[0] = Pairing.G1Point( 
            17339567487611838872564993589977931219420935150735782482146627346950552682250,
            16119573293529242569989407588568475562143700405492081281040100158438727365663
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            7792920288348139513598945776698807654360951603927695623415374932330067802883,
            16579686829445515666018218583576262946360811635970921621925554861117387738328
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            20970145776919169941592197037807581974337932135877379160610928557627395164358,
            10009499906957570669119501819459834972155193497545898206082912327523786105655
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            3692254064782288344061150114991358472968070385863628374343763689386481617164,
            3912201568123255059590238596953418615263293651495316988918945302431942036547
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            8510485181301192190016449209207037975013858742195212229569432365426035869033,
            19316347914602178702137038170388239886212716458145017875228709093142053866112
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            7072446504346131111219742013199243903633893790496474389227611571899211439231,
            17694564297560071551764521138610321119330406231186175136220858585165921639010
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            4195991477668958947648346253144546543090328317449648155544327876404097684124,
            1736092949559815591455706930068961481440877013068915647816401232022776017950
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            12318667071086290991687227439185032756632229602114673070174791108032908069866,
            4697743444382282584581613726932372215876425186807083097198502021556976953701
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            3213694126459211002858045072400593683223559917920226719453005189943749418649,
            17343755458215869741159772557726376504342353269803081714373692783386485256417
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            16641036731750394770531997114384435034981404333042848776585054385312284747725,
            673846166277336401672156051874791598774755424489088025773535983100464993894
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            14364927528426583353125645083677445566701803036836036557268939515067787844473,
            10216091479403395800331123913258907119906677134332801699163057131743854265911
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            6967228863059266773635519288046213293303128747047761088052932867701537753344,
            7095541485072985458030165018900936742945959192283817722064585216974202643006
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            20507133739814027188520520047514061953132285794678602385888018560085618757821,
            9535158423689734000904175541353725047633583974509506960545513339378576198704
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            21786358262031484748702445055790077968535712326876843983251890613956503505265,
            10234635688080710682930962809112859315463774492735737933468045241373815205197
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            7652020195931450376203910767840781481611441016618665381799000981829694463146,
            17585301615638816484484477610846920460040826419094214684379506392917725011332
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            13257883606474237159387940770075652829307160185226497225434233536893313675265,
            16593531704725635831230270885887440651830434103134163796333251576718141461940
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            19371908513326743522619494990079164833534370473130952376529081806951351278520,
            8750138401694452336714294127986991754737322156991534453439895227192548040047
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            9417836976693980510401102575348727040211750874711868222726293993295744340021,
            2485074489873188474518809138282453320725876843936512214900767090697880896362
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            16604327584863528928525640323768131720463256341450118427195989816765522327610,
            17691842407089625430819290213471114592285353658684588580243371336266125939493
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            13070559043592582978607555746016791010299030872270622828223589986201514162098,
            20025461707323469308539253542282050569037884414794205791948958540989123204726
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            1405131805078669652075747569864985000858528826494776106620615948863567024674,
            21615127322919669971426546440095784392709654750431454732385565584673334542619
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            7278228661934530713411742914260564835011335691459120483937395051781395609744,
            16323570997896032356715897258616690689381403740385335110612448472336916311737
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            14945211464817049548674313304663656682778292901158798940506686609717495259745,
            11821016974628920562410293738164927079050063975429553608350860012913176271486
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            8227917177468799387178504999236320608665827892585363458195685019358631226377,
            16673229179991278903436723635946759760219686714538713981318003872512483179922
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            849563628085427388152041070779542525929396513272591543760886786136027540630,
            5507225628307602562387484386235749199809775177013720511032575687573795139508
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            13402656190902889766051969767967300119063310171702374662794837366190110732115,
            5881311356505497558881363550777111480683911692948798326439210420953186237340
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            7163496528476523951472468725524539977225559366325226829799927119609790514183,
            10396157408714543045390713126198138639466259498534197662211349855068181756798
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[26] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
