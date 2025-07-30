# pragma version 0.4.3

# Mock data that can be set for testing
mock_price_oracle: public(uint256)
mock_ema_tvl: public(uint256)
mock_coins: public(address[8])
mock_token_index: public(uint256)
mock_no_argument: public(bool)


@deploy
def __init__(_price_oracle: uint256, _ema_tvl: uint256, _token_index: uint256):
    self.mock_price_oracle = _price_oracle
    self.mock_ema_tvl = _ema_tvl
    self.mock_token_index = _token_index
    self.mock_no_argument = False

    # Set up mock coins
    for i: uint256 in range(8):
        self.mock_coins[i] = empty(address)


@external
def set_mock_data(_price_oracle: uint256, _ema_tvl: uint256, _token_index: uint256):
    self.mock_price_oracle = _price_oracle
    self.mock_ema_tvl = _ema_tvl
    self.mock_token_index = _token_index


@external
def set_no_argument(_no_argument: bool):
    self.mock_no_argument = _no_argument


@external
@view
def price_oracle(i: uint256 = 0) -> uint256:
    return self.mock_price_oracle


@external
@view
def ema_tvl() -> uint256:
    return self.mock_ema_tvl


@external
@view
def coins(i: uint256) -> address:
    return self.mock_coins[i]
