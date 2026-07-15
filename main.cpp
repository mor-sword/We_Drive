#include <raylib.h>
#include <math.h>

#define BACKGROUND_COLOR (Color){186, 149, 127}
#define CAR_COLOR BLACK
#define ROTATION_SPEED 120

int main()
{
    int width = 1300;
    int height = 1000;

    InitWindow(width, height, "we_drive");
    SetTargetFPS(60);

    Image car_image = LoadImage("img/Car_1_01.png");
    ImageRotateCCW(&car_image);

    Texture2D car_texture = LoadTextureFromImage(car_image);
    UnloadImage(car_image);

    Rectangle car_texture_rec = {
        .x = 0.0f,
        .y = 0.0f,
        .width = (float)car_texture.width,
        .height = (float)car_texture.height,
    };

    Image bg_image = LoadImage("img/Soil_Tile.png");
    Texture2D bg_texture = LoadTextureFromImage(bg_image);
    UnloadImage(bg_image);

    Rectangle bg_texture_rec = {
        .x = 0.0f,
        .y = 0.0f,
        .width = (float)bg_texture.width,
        .height = (float)bg_texture.height,
    };

    Rectangle bg_rec = {
        .x = 0.0f,
        .y = 0.0f,
        .width = (float)width,
        .height = (float)height,
    };

    Vector2 bg_origin = {
        .x = 0.0f,
        .y = 0.0f,
    };

    float car_width = 150;
    float car_height = 190;
    float car_x = width / 2.0 - car_width / 2.0;
    float car_y = height / 2.0 - car_height / 2.0;
    float car_speed = 0;
    float car_maxspeed = 20;
    int car_direction = 0;
    float car_rotation = 90;

    Camera2D camera = {0};

    camera.target = (Vector2){car_x, car_y};
    camera.offset = (Vector2){width / 2, height / 2};
    camera.rotation = 0.0f;
    camera.zoom = 1.0f;

    while (WindowShouldClose() != 1)
    {
        float dt = GetFrameTime();

        BeginDrawing();
        ClearBackground(BACKGROUND_COLOR);

        if (IsKeyDown(KEY_UP))
        {
            car_direction = -1;
            car_speed = car_speed + 5 * dt;

            if (car_speed > car_maxspeed)
                car_speed = car_maxspeed;
        }
        else if (IsKeyDown(KEY_DOWN))
        {
            car_direction = 1;
            car_speed = car_speed - 10 * dt;

            if (fabsf(car_speed) > car_maxspeed)
                car_speed = -car_maxspeed;
        }
        else
        {
            car_speed = car_speed + 2 * dt * car_direction;

            if (car_direction == -1 && car_speed < 0)
                car_speed = 0;
            else if (car_direction == 1 && car_speed > 0)
                car_speed = 0;
        }

        if (IsKeyDown(KEY_LEFT))
            car_rotation = car_rotation - ROTATION_SPEED * dt;
        else if (IsKeyDown(KEY_RIGHT))
            car_rotation = car_rotation + ROTATION_SPEED * dt;

        float degree_to_rad = PI * car_rotation / 180;

        float x_shifts = car_speed * cos(degree_to_rad);
        float y_shifts = car_speed * sin(degree_to_rad);

        car_x = car_x + x_shifts;
        car_y = car_y + y_shifts;

        Rectangle car_rec = {
            .x = car_x,
            .y = car_y,
            .width = car_height,
            .height = car_width,
        };

        Vector2 car_origin = {
            .x = car_height / 2,
            .y = car_width / 2,
        };

        DrawTexturePro(bg_texture, bg_texture_rec, bg_rec, bg_origin, 0.0f, WHITE);

        BeginMode2D(camera);

        DrawTexturePro(car_texture, car_texture_rec, car_rec, car_origin, car_rotation, WHITE);

        EndMode2D();

        EndDrawing();
    }

    UnloadTexture(car_texture);
    UnloadTexture(bg_texture);

    CloseWindow();

    return 0;
}