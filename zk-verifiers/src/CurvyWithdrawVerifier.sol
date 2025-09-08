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
            [14827391605059791348576777583489258517113818747433262141220035261800164092351,
             3590053952101750516249075490135165079321386546521274516573174684189977479584],
            [18704350247127236762443895514763452147666463838420127419718850205967280543193,
             18185309709204008566027046848498045918388745588036683436077023610152157106414]
        );
        vk.IC = new Pairing.G1Point[](17);
        
        vk.IC[0] = Pairing.G1Point( 
            17339567487611838872564993589977931219420935150735782482146627346950552682250,
            16119573293529242569989407588568475562143700405492081281040100158438727365663
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            7792920288348139513598945776698807654360951603927695623415374932330067802883,
            16579686829445515666018218583576262946360811635970921621925554861117387738328
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            4479506429215219231921128780671623428954397770996512134015313174496315731205,
            19830961437851850549085016757230694996633164979008949205009235238293459173423
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
            11027583261619628907003056953972546278098173181612438532240613337247710033949,
            1184869036473463365886473549286962874649404327416615941177754437109464936343
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            3709293154029737271413973617796136524086524597539733811161676165284400588530,
            3596784313991699426081218171717047082985840319534736077473994171894582286708
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            1240967500112168063546633153788361703059756389183625171829595908405108934507,
            2434520925945482893588007632506201483423037268384705238872902611868214689619
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            3757800335978139676288020071033482302573649110974116579578001121944103024922,
            13708373355200618400143514955009720967556727913892373433106534276008599624475
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            12669348132155296086884154343964550050707212558340212391388578179644792589382,
            4081208255810731415745268266269434309959996194212228011795803830450265634803
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            10937131381515971708579022857177192973374239025374906810944561875149421768502,
            13119585947987345227988329657605253900470085750435517286124577600241583041296
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            21205144624786983403661723434647624829302326910918102201858949623236595547056,
            15340016104375567837216955524279121611672239998988001004279449770262452851314
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            16612372041434636362961369500449432233027841319793186452828860970940606452611,
            10985674968128426499272033896181975051764614379644526858834782977697981419001
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            1719675614205673666358339711776503295068758352543408745075552570107095865483,
            2004544774558503392027363712081087335051627038133425239074255986797356167759
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            4560054547479243141718403099656170044165948255560652155122531191186817135944,
            13073191149909178462558041422322151559843880217883668544003310568162374701441
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            4217796126356714951860970293445093193045914243879330426557366079540756258898,
            9272623404487177074654759153208345761084136139374919874370161539554216115968
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            19265812485143576629330990596261396506079745964829956107807207567079713761661,
            16644693053939790124036958243580801851258037426559974275933545229487117880323
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
            uint[16] memory input
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
