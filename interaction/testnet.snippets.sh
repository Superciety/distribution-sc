DEPLOYER="./deployer.pem"
ADDRESS=$(erdpy data load --partition testnet --key=address)
DEPLOY_TRANSACTION=$(erdpy data load --partition testnet --key=deploy-transaction)
PROXY=https://testnet-api.elrond.com

DISTRIBUTABLE_TOKEN_ID=0x5853555045522d373261313564 # XSUPER-72a15d
DISTRIBUTABLE_TOKEN_PRICE=000020000000000000 # 0.00002 EGLD

deploy() {
    echo "building contract ..."
    erdpy --verbose contract build

    echo "deploying to testnet ..."
    erdpy --verbose contract deploy --project . \
        --arguments ${DISTRIBUTABLE_TOKEN_ID} ${DISTRIBUTABLE_TOKEN_PRICE} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=20000000 \
        --outfile="deploy-testnet.interaction.json" \
        --send --proxy=${PROXY} --chain=T || return

    TRANSACTION=$(erdpy data parse --file="deploy-testnet.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(erdpy data parse --file="deploy-testnet.interaction.json" --expression="data['emitted_tx']['address']")

    erdpy data store --partition testnet --key=address --value=${ADDRESS}
    erdpy data store --partition testnet --key=deploy-transaction --value=${TRANSACTION}

    echo ""
    echo "smart contract address: ${ADDRESS}"
}

# params:
#   $1 = token amount
deposit() {
    method_name="0x$(echo -n 'deposit' | xxd -p -u | tr -d '\n')"

    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="ESDTTransfer" \
        --arguments ${DISTRIBUTABLE_TOKEN_ID} $1 $method_name \
        --send --proxy=${PROXY} --chain=T \
}
