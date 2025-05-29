# Variables with cematic
> Type definition with cematic:
````c++
    typedef(unsigned __int64, u64_t);
    typedef(struct { char* val, int len; }, str_t);
    typedef(struct { float x; float y; float z; }, vec3_t);
    
    typedef(struct {
        u64_t uuid;
        str_t name;
        vec3_t pos;
        vec3_t velo;
    }, player_t);
````
Cematic abstracts the error handling away and declares for every ``type`` an
``expect_type``/``expect(type)`` type.
````c++
void char_heal(world_t world) {
    const expect(player_t) player = get_player(world);
    if (!player.nil) {
        player_heal(player.val);
        return;
    }
    io.print("Error while gets player of world: " + player.err)
}
````

>Heap allocation with cematic:
````c++
void main(void) {
    const expect(vec3_t) vec = new(vec3_t);
    if (vec.nil) return;
    
    vec.val.x = 0;
    vec.val.y = 0;
    vec.val.z = 0;
    
    vec3_t* ptr = &vec.val;
    other_func(ptr);
}
````