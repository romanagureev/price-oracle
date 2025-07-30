from enum import Enum


# Using Chain ID for unique values
class Chain(Enum):
    FRAXTAL = 252


CHAINS_DICT = {
    Chain.FRAXTAL: {"rpc": "https://rpc.frax.com"},
}
