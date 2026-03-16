local Coord = function (x, y)
    return {x = x, y = y}
end


local snake_delay = 0.1 -- in second
local snake_delay_timer = 0
local grid_count = 20

-- Grid Layout
--[[
1, 2, 3, 4, 5, ...
2, ...............
3, ...............
4, ...............
5, ...............
.
.
.
]]--

local SnakeTarget = {
    UP    = 1,
    RIGHT = 2,
    DOWN  = 3,
    LEFT  = 4,
}

local snake_last_target
local snake_move_stack
local snake
local lose
local food

local __temp_coord = Coord(0,0)

local function reset()
    lose = false

    snake_last_target = SnakeTarget.RIGHT
    snake_move_stack  = {}

    snake = {}
    snake[1] = Coord(3, 5)
    snake[2] = Coord(2, 5)
    snake[3] = Coord(1, 5)

    food = Coord(7, 5)
end

local function grid_tile_is_empty(x, y)
    for index, coord in ipairs(snake) do
        if coord.x == x and coord.y == y then
            return false, index
        end
    end

    return true, 0
end

local function grid_tile_target_to_coord(base_coord, dest_coord, target)
    dest_coord.x = base_coord.x
    dest_coord.y = base_coord.y

    if target == SnakeTarget.UP then
        dest_coord.y = dest_coord.y - 1

        if dest_coord.y < 1 then
            dest_coord.y = grid_count
        end

    elseif target == SnakeTarget.RIGHT then
        dest_coord.x = dest_coord.x + 1

        if dest_coord.x > grid_count then
            dest_coord.x = 1
        end

    elseif target == SnakeTarget.DOWN then
        dest_coord.y = dest_coord.y + 1

        if dest_coord.y > grid_count then
            dest_coord.y = 1
        end

    elseif target == SnakeTarget.LEFT then
        dest_coord.x = dest_coord.x - 1

        if dest_coord.x < 1 then
            dest_coord.x = grid_count
        end
    end
end

local function push_snake_target_up()
    table.insert(snake_move_stack, SnakeTarget.UP)
end

local function push_snake_target_right()
    table.insert(snake_move_stack, SnakeTarget.RIGHT)
end

local function push_snake_target_down()
    table.insert(snake_move_stack, SnakeTarget.DOWN)
end

local function push_snake_target_left()
    table.insert(snake_move_stack, SnakeTarget.LEFT)
end

local function pop_snake_target()
    if #snake_move_stack == 0 then
        return nil
    end

    return table.remove(snake_move_stack, 1)
end

local function move_snake_head(target)
    grid_tile_target_to_coord(snake[1], snake[1], target)
end

local function move_snake()
    local target = pop_snake_target()

    if not target then
        target = snake_last_target
    end

    local target_cood = __temp_coord
    grid_tile_target_to_coord(snake[1], target_cood, target)
    local is_empty, index = grid_tile_is_empty(target_cood.x, target_cood.y)
    
    if not is_empty then
        if index ~= 2 then
            lose = true
            return
        end

        target = snake_last_target
    end

    for i=#snake, 2, -1 do
        snake[i].x = snake[i-1].x
        snake[i].y = snake[i-1].y
    end

    move_snake_head(target)
    snake_last_target = target
end

local function grow_snake()
    table.insert(snake, Coord(-10, -10))
end

local function spawn_random_food()
    food.x = math.floor(1 + math.random() * (grid_count-1))
    food.y = math.floor(1 + math.random() * (grid_count-1))
end

local function spawn_first_empty_tile_food()
    for y=1, grid_count-1 do
        for x=1, grid_count-1 do
            if grid_tile_is_empty(x, y) then
                food.x = x
                food.y = y
                return true
            end
        end
    end

    return false
end

local font
function love.load()
    font = love.graphics.newFont("Aileron-Bold.otf", 28)

    reset()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
end

function love.update(dt)
    if lose then return end

    snake_delay_timer = snake_delay_timer + dt
    while snake_delay_timer > snake_delay do
        snake_delay_timer = snake_delay_timer - snake_delay
        move_snake()

        local head = snake[1]
        if head.x == food.x and head.y == food.y then
            grow_snake()
            spawn_random_food()

            local attemp = 1
            local max_attemp = 10
            while not grid_tile_is_empty(food.x, food.y) do
                spawn_random_food()
                attemp = attemp + 1

                if attemp > max_attemp then
                    if not spawn_first_empty_tile_food() then
                        assert(false, "Do something")
                    end

                    break
                end
            end
        end
    end
end

function love.draw()
    love.graphics.setFont(font)

    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print(tostring(#snake_move_stack), 10, 10)
    -- love.graphics.print("Food at: " .. food.x .. " x " .. food.y, 10, 40)

    local sw = love.graphics.getWidth()
    local tile_size = sw/grid_count

    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", (food.x-1) * tile_size, (food.y-1) * tile_size, tile_size, tile_size)

    for _,coord in ipairs(snake) do
        love.graphics.setColor(0.1, 0.8, 0.1)
        love.graphics.rectangle("fill", (coord.x-1) * tile_size, (coord.y-1) * tile_size, tile_size, tile_size)
    end

    if lose then
        love.graphics.setColor(0.8, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", 0, 0, sw, sw)

        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.printf("Point: " .. #snake - 3 .. "\nPress SPACE", 0, sw/2 - 28, sw, "center")
    end
end

function love.keypressed(key)
    if key == "q" then
        love.event.quit()
    elseif key == "space" then
        if lose then reset() end
    elseif key == "up" then
        push_snake_target_up()
    elseif key == "right" then
        push_snake_target_right()
    elseif key == "down" then
        push_snake_target_down()
    elseif key == "left" then
        push_snake_target_left()
    end
end
