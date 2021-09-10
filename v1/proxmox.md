# ProxMox

Current setup is utilizing an old Mac Mini from early 2012, Intel Core i5-3210M @2.5GHz with 4gb of RAM and a 500gb Crucial SSD. Currently this does the job but will look into maxing its memory out to 16gb.

## Systems Running

Here are the current machines running on the little Prox box:

### Always On

- PiHole
- OpenMediaVault

### Sometimes ON

- Kali Linux
- Grafana
- Ubuntu 21.05
- Qubes

## Troubleshooting and Tips

### Adding USB passthrough to VM

1. From the main box `pve` run `lsusb` to locate the usb device you want to passthrough, keep track of the 8 character ID that is split with a colon.

2. Run the following with both the ID of the USB device you want to passthrough and the ID of the VM you want to pass it to:

    `qm set <VM-ID> -usb<USB Number you would like to label it> host=<the USB ID>`

3. Restart the VM you are passing the device to and you should be good to go, you can verify this by running `lsusb` command in that VM and you should see it listed.