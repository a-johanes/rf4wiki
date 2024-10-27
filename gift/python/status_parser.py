from enum import IntFlag
from typing import List

class StatusEffect(IntFlag):
    # Healing effects (bits 1-6)
    HEAL_PSN = 1 << 0    # bit 1
    HEAL_SEAL = 1 << 1   # bit 2
    HEAL_PAR = 1 << 2    # bit 3
    HEAL_SLP = 1 << 3    # bit 4
    HEAL_FTG = 1 << 4    # bit 5
    HEAL_SICK = 1 << 5   # bit 6

    # Status ailments (bits 7-12)
    PSN = 1 << 6     # bit 7
    SEAL = 1 << 7    # bit 8
    PAR = 1 << 8     # bit 9
    SLP = 1 << 9     # bit 10
    FTG = 1 << 10    # bit 11
    SICK = 1 << 11   # bit 12

    # Special effects
    LEVEL_UP = 1 << 13  # bit 14 (0x2000)
    DEBUFF = 1 << 14    # bit 15 (0x4000)

# Mapping for heal effect names
HEAL_NAME_MAP = {
    StatusEffect.HEAL_PSN: "PSN",
    StatusEffect.HEAL_SEAL: "SEAL",
    StatusEffect.HEAL_PAR: "PAR",
    StatusEffect.HEAL_SLP: "SLP",
    StatusEffect.HEAL_FTG: "FTG",
    StatusEffect.HEAL_SICK: "SICK"
}

# Mapping for status ailment names
AILMENT_NAME_MAP = {
    StatusEffect.PSN: "PSN",
    StatusEffect.SEAL: "SEAL",
    StatusEffect.PAR: "PAR",
    StatusEffect.SLP: "SLP",
    StatusEffect.FTG: "FTG",
    StatusEffect.SICK: "SICK"
}

def parse_status_hex(hex_string: str) -> str:
    """
    Parse a space-separated hex string and return healing effects, status ailments, and special effects.

    Args:
        hex_string: A space-separated hexadecimal string (e.g. "00 00 0F C0")

    Returns:
        A string describing the active effects
    """
    # Remove spaces and convert to a single number
    hex_value = int(''.join(hex_string.split()), 16)

    # Check for special effects first
    if hex_value & StatusEffect.DEBUFF:
        return "HP -20%<br/>RP max -10%<br/>STR -10%<br/>VIT -10%<br/>INT -10%"

    if hex_value & StatusEffect.LEVEL_UP:
        return "Increase Level"

    # Check for healing effects
    heal_effects = []
    for effect in HEAL_NAME_MAP:
        if hex_value & effect:
            heal_effects.append(HEAL_NAME_MAP[effect])

    # Check for status ailments
    ailments = []
    for effect in AILMENT_NAME_MAP:
        if hex_value & effect:
            ailments.append(AILMENT_NAME_MAP[effect])

    # Build output string
    result = []
    if heal_effects:
        result.append(f"Heal: {' '.join(heal_effects)}")
    if ailments:
        result.append(f"Status Ailments: {' '.join(ailments)}")

    return "<br/>".join(result) if result else ""

# Example usage
if __name__ == "__main__":
    # Test level up
    test_level = "2000"
    print(parse_status_hex(test_level))  # Should output: "Increase Level"

    # Test debuff
    test_debuff = "4000"
    print(parse_status_hex(test_debuff))  # Should output: "HP -20%<br/>RP max -10%<br/>STR -10%<br/>VIT -10%<br/>INT -10%"

    # Test healing effects
    test_heal = "00 00 00 3F"
    print(parse_status_hex(test_heal))  # Should output: "Heal: PSN SEAL PAR SLP FTG SICK"

    # Test status ailments
    test_ailments = "00 00 0F C0"
    print(parse_status_hex(test_ailments))  # Should output: "Status Ailments: PSN SEAL PAR SLP FTG SICK"

    # Test both
    test_both = "00 00 0F FF"
    print(parse_status_hex(test_both))  # Should output: "Heal: PSN SEAL PAR SLP FTG SICK | Status Ailments: PSN SEAL PAR SLP FTG SICK"

    # Test none
    test_none = "00 00 00 00"
    print(parse_status_hex(test_none))  # Should output: "" (empty string)