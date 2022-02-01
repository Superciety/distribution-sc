##### - configuration - #####
NETWORK_NAME="testnet" # devnet, testnet, mainnet
DEPLOYER="./deployer.pem" # main actor pem file
PROXY=https://testnet-gateway.elrond.com
CHAIN_ID="T"

DISTRIBUTABLE_TOKEN_ID="" # super token id
DISTRIBUTABLE_TOKEN_PRICE=200000000000000 # 0.0002 EGLD

##### - configuration end - #####

DISTRIBUTABLE_TOKEN_ID_HEX="0x$(echo -n ${DISTRIBUTABLE_TOKEN_ID} | xxd -p -u | tr -d '\n')"

ADDRESS=$(erdpy data load --partition ${NETWORK_NAME} --key=address)
DEPLOY_TRANSACTION=$(erdpy data load --partition ${NETWORK_NAME} --key=deploy-transaction)

deploy() {

    echo "accidental deploy protection is activated."
    exit 1;

    echo "building contract for deployment ..."
    erdpy --verbose contract build || return

    echo "running tests ..."
    erdpy --verbose contract test || return

    echo "deploying to ${NETWORK_NAME} ..."
    erdpy --verbose contract deploy \
        --project . \
        --arguments ${DISTRIBUTABLE_TOKEN_ID_HEX} ${DISTRIBUTABLE_TOKEN_PRICE} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=50000000 \
        --outfile="deploy-${NETWORK_NAME}.interaction.json" \
        --proxy=${PROXY} \
        --chain=${CHAIN_ID} \
        --send || return

    TRANSACTION=$(erdpy data parse --file="deploy-${NETWORK_NAME}.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(erdpy data parse --file="deploy-${NETWORK_NAME}.interaction.json" --expression="data['emitted_tx']['address']")

    erdpy data store --partition ${NETWORK_NAME} --key=address --value=${ADDRESS}
    erdpy data store --partition ${NETWORK_NAME} --key=deploy-transaction --value=${TRANSACTION}

    echo ""
    echo "deployed smart contract address: ${ADDRESS}"
}

upgrade() {
    echo "building contract for upgrade ..."
    erdpy --verbose contract build || return

    echo "running tests ..."
    erdpy --verbose contract test || return

    echo "upgrading contract ${ADDRESS} to ${NETWORK_NAME} ..."
    erdpy --verbose contract upgrade ${ADDRESS} \
        --project . \
        --arguments ${DISTRIBUTABLE_TOKEN_ID_HEX} ${DISTRIBUTABLE_TOKEN_PRICE} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=20000000 \
        --proxy=${PROXY} \
        --chain=${CHAIN_ID} \
        --send || return

    echo ""
    echo "upgraded smart contract"
}

# params:
#   $1 = token amount
deposit() {
    method_name="0x$(echo -n 'deposit' | xxd -p -u | tr -d '\n')"

    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="ESDTTransfer" \
        --arguments ${DISTRIBUTABLE_TOKEN_ID_HEX} $1 $method_name \
        --proxy=${PROXY} \
        --chain=${CHAIN_ID} \
        --send || return
}

updatePrice() {
    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="updatePrice" \
        --arguments $DISTRIBUTABLE_TOKEN_PRICE \
        --proxy=$PROXY \
        --chain=$CHAIN_ID \
        --send || return
}

claim() {
    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="claim" \
        --proxy=$PROXY \
        --chain=$CHAIN_ID \
        --send || return
}

# params:
#   $1 = amount
claimDistributable() {
    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="claimDistributable" \
        --arguments $1 \
        --proxy=$PROXY \
        --chain=$CHAIN_ID \
        --send || return
}

pause() {
    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="pause" \
        --proxy=$PROXY \
        --chain=$CHAIN_ID \
        --send || return
}

unpause() {
    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="unpause" \
        --proxy=$PROXY \
        --chain=$CHAIN_ID \
        --send || return
}

# params:
#   $1 = limit price
updateBuyLimit() {
    erdpy --verbose contract call ${ADDRESS} \
        --recall-nonce \
        --pem=${DEPLOYER} \
        --gas-limit=5000000 \
        --function="updateBuyLimit" \
        --arguments $1 \
        --proxy=$PROXY \
        --chain=$CHAIN_ID \
        --send || return
}
