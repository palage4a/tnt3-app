# tnt3-hello-app
## setup
### install vshard
```sh
tt rocks install vshard
```

### start instances
```sh
tarantool -c config.yml -n router-001
tarantool -c config.yml -n storage-001
tarantool -c config.yml -n storage-001
```

### init storages
#### setup leader
```sh
tt connect client:secret@127.0.0.1:3301
```

run lua
```sh
    box.schema.space.create("test", {if_not_exists = true})
    box.space.test:format({
         {name = "id", type="unsigned"},
         {name = "bucket_id", type="unsigned"},
         {name = "value", type="string"},
     })
    box.space.test:create_index("pri", {parts = {'id'}}, {if_not_exists = true})
    box.space.test:create_index("bucket_id", {parts = {'bucket_id'}, unique = false}, {if_not_exists = true})

    function put(...)
        return box.space.test:put(...)
    end

    function get(id)
        return box.space.test:get({id})
    end

    function pull(id, limit)
        limit = tonumber(limit) or 10
        limit = math.min(limit, 1000)
        return box.space.test:select({id}, {iterator="GE", limit=limit})
    end
```

#### setup replica
```sh
tt connect client:secret@127.0.0.1:3302
```

run this lua code
```sh
    function get(id)
        return box.space.test:get({id})
    end

    function pull(id, limit)
        limit = tonumber(limit) or 10
        limit = math.min(limit, 1000)
        return box.space.test:select({id}, {iterator="GE", limit=limit})
    end
```

### bootstrap router
```sh
tt connect client:secret@127.0.0.1:3300
```

run this lua code
```sh
vshard = require('vshard')
vshard.router.bootstrap()
```

## example

```s
$ tt connect client:secret@127.0.0.1:3300
   • Connecting to the instance...
   • Connected to 127.0.0.1:3300
127.0.0.1:3300> bucket_id = vshard.router.bucket_id_strcrc32(1)
---
...

127.0.0.1:3300> vshard.router.callrw(bucket_id, "put", {{1, bucket_id, "value"}})
---
- [1, 2477, 'value']
...

127.0.0.1:3300> vshard.router.callro(bucket_id, "get", {1})
---
- [1, 2477, 'value']
...
127.0.0.1:3300> vshard.router.callro(bucket_id, "pull", {1})
---
- [[1, 2477, 'value']]
...
```
