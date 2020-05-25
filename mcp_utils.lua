-- Seed the random number generator. Lua seems to be weird about this,
-- so also generate a few random numbers to kick it into gear.
math.randomseed(os.clock() ^ 5);
for i = 1, 10 do
    math.random(10000, 65000);
end

-- Find the highest version in common between two sets of versions.
function supported_version(client_min, client_max, server_min, server_max)
    if client_max >= server_min and server_max >= client_min then
        return math.min(server_max, client_max);
    else
        return false;
    end
end

-- Generate an MCP authentication key. As it's designed to prevent spoofing,
-- and not for security, this key is 20 random digits.
function generate_auth_key()
   	local res = "";
	for i = 1, 20 do
		res = res .. math.random(0, 9);
	end
	return res;
end
