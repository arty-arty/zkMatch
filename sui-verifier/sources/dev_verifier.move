module dev::verifier {
    use sui::tx_context::{TxContext};
    use std::vector::append;
    use std::debug;
    use sui::groth16::{Curve, public_proof_inputs_from_bytes, prepare_verifying_key, 
    proof_points_from_bytes, verify_groth16_proof,  bn254};
    use sui::hex;
    use std::string::{Self, String};
    //  public entry fun verify(proof: vector<u8>, public_1: vector<u8>, public_2: vector<u8>) {
    //     let proof_serialized = hex::decode(proof);
    //     let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
    //     let curve: Curve = bn254();
    //     let public_inputs_serialized: vector<u8> = x"";
    //     append(&mut public_inputs_serialized, hex::decode(public_1));
    //     append(&mut public_inputs_serialized, hex::decode(public_2));
    //     //let proof_serialized: vector<u8> = x"887cca600d0c168ad9a4db59ac8aaeb1519bc821a0af0b5df7e459eb82660c152d1bbc390bf3b03155a8530ede05265d8c8574aece938c9d54f6950993891f7808d694c4352ef93dd1bb59e272a383e4a07c4e60a5d847f6b395dc24a00b59c5173b7a96843a2c5d1516b0ba68c96829f1a02e005dcb4d41406088a8b5d4deac527ff89db2ddc497414bdb35c229a7c786b7678ce2d5e23de57634f84567cb55b651cb5ee4910473965e2fd60755d6c89314add6024d59ea737e5bc769f9c3a8";
        

    
    //     let pvk = prepare_verifying_key(&curve, &vk_serialized);
        
    //     let public_inputs =  public_proof_inputs_from_bytes(public_inputs_serialized);
    //     let proof_points =  proof_points_from_bytes(proof_serialized);

    //     let verification_result: bool = verify_groth16_proof(&curve, &pvk, &public_inputs, &proof_points);
        
    //     //let a: u64 = 64;
    //     assert!(verification_result, 1337);
    // }

    //Shared object Map
    //Quest_id - would be kP_x, kP_y
    struct Quest{
        question: String,
        professor_k_hash: vector<u8>,
        professor_kP_x: vector<u8>,
        professor_kP_y: vector<u8>
    }

    public entry fun professor_create_quest()
    {
        //Immediately asserts that professot commitment is valid
        //(He used this hashed k to multiply by private input P and got public kP_x, kP_y)
        //Only then creates a shared object - quest
        //Writes question text, k_hash, kP_x, kP_y
    }

    public entry fun student_answer_question(shared_quest: Quest)
    {
        //Check that I did not answer alread i.e Answers map does not have caller address key
        //Take collateral money

    }

    public entry fun student_answer_question(shared_quest: Quest)
    {
        //Check that I did not answer alread i.e Answers map does not have caller address key
        //Take collateral money

    }

    public entry fun student_get_timeout_reward(shared_quest: Quest, collateral : Collateral, )
    {
        //Lookup by caller address answer in shared_quest
        //Make sure there is one
        //Retrieve its timestamp: Do later when everything else is done
        //Use clock to get current: Do later when everything else is done
        //If professor (oracle) did not check the answer in 2 minutes
        //Pop answer 
        //Reward the caller with credit struct
    }

    //Incentive structure
    //Create a struct called academic credit or something

    fun verify(proof: vector<u8>, vk_serialized: vector<u8>, public_inputs_serialized: vector<u8>): bool {
        let proof_serialized = hex::decode(proof);
        let curve: Curve = bn254();
        let pvk = prepare_verifying_key(&curve, &vk_serialized);
        let public_inputs =  public_proof_inputs_from_bytes(public_inputs_serialized);
        let proof_points =  proof_points_from_bytes(proof_serialized);
        verify_groth16_proof(&curve, &pvk, &public_inputs, &proof_points)
    }

    fun commit(proof: vector<u8>, public_out_hash_a: vector<u8>, public_out_aP_x: vector<u8>, public_out_aP_y: vector<u8>, public_in_address: vector<u8>) {
        let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
        let public_inputs_serialized: vector<u8> = x"";
        append(&mut public_inputs_serialized, hex::decode(public_out_hash_a));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_x));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_y));
        append(&mut public_inputs_serialized, hex::decode(public_in_address));

        let verification_result: bool = verify(proof, vk_serialized, public_inputs_serialized);
        assert!(verification_result, 1337);

    }

    fun unlock(proof: vector<u8>, public_out_kaH_x: vector<u8>, public_out_kaH_y: vector<u8>, public_out_aP_x: vector<u8>, public_out_aP_y: vector<u8>, public_in_address: vector<u8>) {
        let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
        let public_inputs_serialized: vector<u8> = x"";
        append(&mut public_inputs_serialized, hex::decode(public_out_hash_a));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_x));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_y));
        append(&mut public_inputs_serialized, hex::decode(public_in_address));

    
    
        let verification_result: bool = verify(proof, vk_serialized, public_inputs_serialized);
        assert!(verification_result, 1337);

    }

    //fun init(_ctx: &mut TxContext) {
        // transfer::transfer(CreatorCapability {
        //     id: object::new(ctx),
        // }, tx_context::sender(ctx))
        // let proof = b"a27c5205f9dfb4829a0c953d179dc171c23f5bb22ab4c866f0c090017e1ba60ab7a0f44108483acde4a05b294afafa2e2a751a0e4c6c8dc2e448161f5b35e02beaf88f2e9a8c9c5231a40083815dd30d4ad8db5a4552c3e40a67446625e1d008d4dc78a664286ca26be6ab055f1879b36f6d33f94d30581806439cf99ed9d593";
        // let public_1 = b"8101000000000000000000000000000000000000000000000000000000000000";
        // let public_2 = b"0500000000000000000000000000000000000000000000000000000000000000";
        // verify(proof, public_1, public_2);
    }




//     #[test]
//     public fun test_verify(){
//         let proof = b"a27c5205f9dfb4829a0c953d179dc171c23f5bb22ab4c866f0c090017e1ba60ab7a0f44108483acde4a05b294afafa2e2a751a0e4c6c8dc2e448161f5b35e02beaf88f2e9a8c9c5231a40083815dd30d4ad8db5a4552c3e40a67446625e1d008d4dc78a664286ca26be6ab055f1879b36f6d33f94d30581806439cf99ed9d593";
//         let public_1 = b"8101000000000000000000000000000000000000000000000000000000000000";
//         let public_2 = b"0500000000000000000000000000000000000000000000000000000000000000";
//         verify(proof, public_1, public_2);
//         //assert!(64==verify(), 1);
//         let n = 64u64;
//         debug::print(&n);
//     }
// }