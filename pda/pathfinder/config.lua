local C = {}
C.SPACE_CELL_SIZE = 32
C.CHUNK_CELL_SIZE = 128
C.UNIT_SIZE = 0.2
C.OBJECT_TYPES = {
    ENTITY = "entity",
    TILE = "tile",
    REGION = "region"
}
C.DISPLAY_TTL = 9000
C.SMALL = 10e-8
C.GROW_STEP = 1
C.STEP_PER_TICK = 2

return C
