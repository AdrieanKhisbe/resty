

describe "Resty"

    describe "Basic"
        it "load resty function without error"
           . ./resty -W # source resty with no history mode
           assert equal $? 0
        end

        it "can define a target"
            output=$(resty localhost:4004 2>&1 )
            assert equal $? 0
            assert equal "$output" "http://localhost:4004*"
        end

        # Launch server
        resty localhost:4004 2>/dev/null

        it "can access to it with a get"
            output=$(GET / 2>&1)
            assert present "$output"
        end
        it "get the good content"
            output=$(GET /simple.txt)
            assert equal "$output" "hi there"
        end

    end


    describe "HTTP Verbs"
        data='data here'
        it "GET"
            output=$(GET /echo)
            assert equal "$output" "get"
        end
        it "GET with query string"
            output=$(GET "/echo?a=b" -Q)
            assert equal "$output" 'get\n{"a":"b"}'
        end

        it "GET with query string by argument"
            output=$(GET /echo -q "a=b")
            assert equal "$output" 'get\n{"a":"b"}'
        end
        it "POST with data"
            output=$(POST /echo "$data")
            assert equal "$output" "post\n$data"
        end
        it "POST with data and query parameter"
            output=$(POST /echo "$data" -q "a=b")
            assert equal "$output" 'post\n'"$data"'\n{"a":"b"}'
        end
        it "PUT with data"
            output=$(PUT /echo "$data")
            assert equal "$output" "put\n$data"
        end
        it "PUT with data and query parameter"
            output=$(PUT /echo "$data" -q "a=b")
            assert equal "$output" 'put\n'"$data"'\n{"a":"b"}'
        end
        it "PATCH with data"
            output=$(PATCH /echo "$data")
            assert equal "$output" "patch\n$data"
        end
        it "PATCH with data and query parameter"
            output=$(PATCH /echo "$data" -q "a=b")
            assert equal "$output" 'patch\n'"$data"'\n{"a":"b"}'
        end
        it "DELETE"
            output=$(DELETE /echo)
            assert equal "$output" "delete"
        end
        it "DELETE with data"
            output=$(DELETE /echo "$data")
            assert equal "$output" "delete\n$data"
        end
        it "TRACE"
            output=$(TRACE /echo "$data")
            assert equal "$output" "trace\n$data"
        end
        it "OPTIONS"
            output=$(OPTIONS /echo)
            assert equal "$output" "options"
        end
        it "HEAD"
            output=$(HEAD /echo)
            assert match  "$output" "200"
        end

    end

    describe "Viewer"

        it "prety format when lynx is installed"
            output=$(GET /simple.html | tr -d ' ')
            assert match $(which lynx) lynx
            assert equal "$output" "$(cat test/test-data/simple-html-lynx.txt | tr -d ' ')"
            # note : hack to cope with lynx version differencies and different handling of table headers
        end
        it "does not prety format on raw mode"
            output=$(GET /simple.html -Z)
            assert equal "$output" "$(< test/data/simple.html)"
        end
        it "json pretty-print formatting with pypp"
            output=$(GET /simple.json | ./pypp)
            assert equal "$output" '{\n    "bar": {
        "cat": "meow",\n        "dog": "woof",\n        "fish": "banana"\n    },\n    "foo": [
        1,\n        2,\n        3\n    ]\n}'
        end
    end

    describe "Options"
         it "GET with headers"
            output=$(GET /echo -v 2> /tmp/resty-getheader-error)
            erroroutput=$(< /tmp/resty-getheader-error)
            assert equal "$output" "get"
            assert match "$erroroutput" "content-type:\ text/plain\;\ charset=utf-8"
            assert match "$erroroutput" "cache-control:\ no-cache"
        end

        it "POST with data sent in query string"
            output=$(POST /echo -d foo=bar -G)
            assert equal "$output" 'post\n\n{"foo":"bar"}'
        end

        it "POST with extra header and basic auth, data in message body"
            output=$(POST /echo -u "user:secret" -H "Accept: application/json" \
                     -v < test/data/simple.json 2> /tmp/resty-getheader-error)
            erroroutput=$(< /tmp/resty-getheader-error)
            assert equal "$output" 'post\n{"foo":[1,2,3],"bar":{"dog":"woof","cat":"meow","fish":"banana"}}'
            assert match "$erroroutput" "Authorization:\ Basic\ dXNlcjpzZWNyZXQ="
            assert match "$erroroutput" "Accept:\ application/json"
        end

    end

end
