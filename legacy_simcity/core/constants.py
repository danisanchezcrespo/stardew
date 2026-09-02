SIDEBAR_WIDTH = 180
ENTITY_RADIUS = 26
GRID_SPACING = 80
ZOOM_FACTOR = 1.1
MIN_SCALE = 0.2
MAX_SCALE = 4.0

SIMULATION_INTERVAL_MS = 100
EDGE_TRANSFER_RATE_PER_SEC = 120.0


# ============================================================
# Worker / Settlement Economy
# ============================================================

# How much food one worker consumes per second
FOOD_PER_WORKER_PER_SEC = 0.05

# How quickly population grows when food is sufficient
WORKER_GROWTH_RATE_PER_SEC = 0.12

# How quickly population declines when food is insufficient
WORKER_DECLINE_RATE_PER_SEC = 0.18

# Attractiveness increases growth speed
ATTRACTIVENESS_GROWTH_BONUS_PER_POINT = 0.05

# Attractiveness reduces decline speed
ATTRACTIVENESS_DECLINE_REDUCTION_PER_POINT = 0.04

# Decline multiplier cannot drop below this
MIN_DECLINE_MULTIPLIER = 0.15