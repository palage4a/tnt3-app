local vshard = require('vshard')

function storage_init(master)-- master only
    if master then
        box.schema.space.create("test", {if_not_exists = true})
        box.space.test:format({
            {name = "id", type="unsigned"},
            {name = "bucket_id", type="unsigned"},
            {name = "value", type="string"},
        })
        box.space.test:create_index("pri", {parts = {'id'}}, {if_not_exists = true})
        box.space.test:create_index("bucket_id", {parts = {'bucket_id'}, unique = false}, {if_not_exists = true})
    end

    -- master + replica
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
end

function router_init()
    vshard.router.bootstrap()
end
