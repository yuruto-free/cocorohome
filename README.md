# COCORO HOME
Control IoT devices using COCORO HOME

## Preparation
Run the following these commands.

```sh
# build
docker-compose build
# create env file
touch .env
```

### Edit .env file
The contents of `.env` file consists of the following:

```dosini
# .env example
DOCKER_COCOROHOME_MEMBERID=your-email-address
DOCKER_COCOROHOME_PASSWORD=your-password
```

### Create a config file (json format)
Execute the following steps to create a config file.

Note: Here, the mitmproxy is used to create the config file.

1. Start mitmproxy and configure the proxy server from your smartphone.
1. Operate the target device from the Web using COCORO HOME application.
1. On the mitmproxy, look for a location where the following request is sent. Here, we use an air conditioner as an example.

    ```
    POST https://cocoroplusapp.jp.sharp/v1/cocoro-air/sync/air-conditioner
    ```

1. Click on the corresponding location and copy the json data displayed in the Request tab. A sample is shown below.

    ```json
    {
        "data": [
            {
                "edt": "0x00",
                "epc": "0xFF"
            },
            {
                "edt": "0x01",
                "epc": "0xFE"
            }
        ],
        "deviceToken": "0123456789abcdef",
        "event_key": "network_control",
        "map_ver": 123456789,
        "model_name": "my-machine"
    }
    ```
1. Repeat for the number of commands and organize them in the following format.

    ```json
    {
      "air-conditioner": {
        "start": {
          "data": [
            {
              "edt": "0x00",
              "epc": "0xFF"
            },
            {
              "edt": "0x01",
              "epc": "0xFE"
            }
          ],
          "deviceToken": "0123456789abcdef",
          "event_key": "network_control",
          "map_ver": 123456789,
          "model_name": "my-machine"
        },
        "stop": {
          "data": [
            {
              "edt": "0x00",
              "epc": "0x01"
            },
            {
              "edt": "0x00",
              "epc": "0x01"
            }
          ],
          "deviceToken": "0123456789abcdef",
          "event_key": "network_control",
          "map_ver": 123456789,
          "model_name": "my-machine"
        }
      }
    }
    ```

1. Save this json file as any file name to `src/config` directory.

### Modify remote_IoT_device.sh
Look for the following description and correspond to the command added to the json file.

```sh
# ===================
# = execute command =
# ===================
target_config=${BASE_DIR}/target.json
case "${exec_mode}" in
#
#   vvvvvvvvvvvv
    start | stop) ### <- modify this line
#   ^^^^^^^^^^^^
#
        cat ${config_path} | ${JQ} ".[\"${target_device}\"].${exec_mode}" > ${target_config}
        execute_command ${target_device} ${target_config}
        rm -f ${target_config}
        ;;

    deviceinfo)
        get_device_list
        ;;

    *)
        ;;
esac
```

## Usage
Execute the following command.

```sh
# Run the container
docker-compose up -d
# Enter the container
docker exec -it cocorohome bash
# Execute the command
/usr/local/bin/remote_IoT_device.sh -config IoT.json -device "air-conditioner" -mode start
# config file:       src/config/IoT.json in host environment (/config/IoT.json in docker environment)
# target device:     air-conditioner
# execution command: start
# -> send json data as following:
#
#    {
#      "data": [
#        {
#          "edt": "0x00",
#          "epc": "0xFF"
#        },
#        {
#          "edt": "0x01",
#          "epc": "0xFE"
#        }
#      ],
#      "deviceToken": "0123456789abcdef",
#      "event_key": "network_control",
#      "map_ver": 123456789,
#      "model_name": "my-machine"
#    }
```
