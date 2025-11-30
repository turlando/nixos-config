{ ovmf }:

{
  name = "Tersicore";
  uuid = "4230a4e4-556a-4e40-84be-112e5b62ce34";
  type = "kvm";

  # metadata = {
  #   libosinfo = {
  #     xmlns = "http://libosinfo.org/xmlns/libvirt/domain/1.0";
  #     os = { id = "http://microsoft.com/win/11"; };
  #   };
  # };

  cpu = {
    mode = "host-passthrough";
    check = "none";
    migratable = true;
    topology = { sockets = 1; dies = 1; clusters = 1; cores = 4; threads = 2; };
  };

  vcpu = { placement = "static"; count = 8; };
  iothreads = { count = 1; };

  cputune = {
    vcpupin = [
      { vcpu = 0; cpuset = "8"; }
      { vcpu = 1; cpuset = "20"; }
      { vcpu = 2; cpuset = "9"; }
      { vcpu = 3; cpuset = "21"; }
      { vcpu = 4; cpuset = "10"; }
      { vcpu = 5; cpuset = "22"; }
      { vcpu = 6; cpuset = "11"; }
      { vcpu = 7; cpuset = "23"; }
    ];

    emulatorpin = { cpuset = "7,19"; };
    iothreadpin = { iothread = 1; cpuset = "7,19"; };

    vcpusched = [
      { vcpus = "0"; scheduler = "fifo"; priority = 1; }
      { vcpus = "1"; scheduler = "fifo"; priority = 1; }
      { vcpus = "2"; scheduler = "fifo"; priority = 1; }
      { vcpus = "3"; scheduler = "fifo"; priority = 1; }
      { vcpus = "4"; scheduler = "fifo"; priority = 1; }
      { vcpus = "5"; scheduler = "fifo"; priority = 1; }
      { vcpus = "6"; scheduler = "fifo"; priority = 1; }
      { vcpus = "7"; scheduler = "fifo"; priority = 1; }
    ];
  };

  memory = { unit = "GiB"; count = 8; };
  currentMemory = { unit = "GiB"; count = 8; };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-9.2";

    # firmware = "efi" causes libvirt to auto-detect firmware, which conflicts
    # with explicit loader/nvram paths and fails in NixOS 25.11.
    #firmware = "efi";

    loader = {
      readonly = true;
      secure = true;
      type = "pflash";
      path = ovmf.firmware;
    };

    nvram = {
      template = ovmf.variablesMs;
      templateFormat = "raw";
      format = "raw";
      path = "/var/lib/libvirt/qemu/nvram/Tersicore_VARS.fd";
    };
  };

  features = {
    acpi = {};
    apic = {};

    hyperv = {
      mode = "custom";
      relaxed = { state = true; };
      vapic = { state = true; };
      spinlocks = { state = true; retries = 8191; };
      vpindex = { state = true; };
      runtime = { state = true; };
      synic = { state = true; };
      stimer = { state = true; };
      frequencies = { state = true; };
      tlbflush = { state = true; };
      ipi = { state = true; };
      avic = { state = true; };
    };

    vmport = { state = false; };
    smm = { state = true; };
  };

  clock = {
    offset = "localtime";
    timer = [
      { name = "rtc"; tickpolicy = "catchup"; }
      { name = "pit"; tickpolicy = "delay"; }
      { name = "hpet"; present = false; }
      { name = "hypervclock"; present = true; }
    ];
  };

  on_poweroff = "destroy";
  on_reboot = "restart";
  on_crash = "destroy";

  pm = {
    "suspend-to-mem" = { enabled = false; };
    "suspend-to-disk" = { enabled = false; };
  };

  devices = {
    # Omit 'emulator' so libvirt chooses the emulator from system config; if you
    # need to pin it, uncomment and use:
    # emulator = "${pkgs.qemu}/bin/qemu-system-x86_64";

    controller = [
      {
        type = "pci";
        index = 0;
        model = "pcie-root";
      }
      {
        type = "virtio-serial";
        index = 0;
      }
      {
        type = "scsi";
        index = 0;
        model = "virtio-scsi";
        driver = { iothread = 1; queues = 4; };
      }
      {
        type = "usb";
        index = 0;
        model = "qemu-xhci";
        ports = 15;
      }
    ];

    iommu = {
      model = "amd";
    };

    memballoon = {
      model = "virtio";
    };

    tpm = {
      model = "tpm-crb";
      backend = { type = "emulator"; version = "2.0"; };
    };

    watchdog = { model = "itco"; action = "reset"; };

    channel = [
      { type = "unix"; target = { type = "virtio"; name = "org.qemu.guest_agent.0"; }; }
      { type = "spicevmc"; target = { type = "virtio"; name = "com.redhat.spice.0"; }; }
    ];

    disk = [
      {
        type = "block";
        device = "disk";
        driver = {
          name = "qemu";
          type = "raw";
          cache = "none";
          io = "native";
          discard = "unmap";
          detect_zeroes = "unmap";
          iothread = 1;
        };
        source = { dev = "/dev/zvol/medea/libvirt/tersicore"; };
        target = { dev = "sda"; bus = "scsi"; };
        boot = { order = 1; };
      }
    ];

    interface = [
      {
        type = "network";
        mac = { address = "52:54:00:13:f9:81"; };
        source = { network = "default"; };
        model = { type = "virtio"; };
      }
    ];

    input = [
      { type = "mouse"; bus = "ps2"; }
      { type = "keyboard"; bus = "ps2"; }
    ];

    # video = {
    #   model = {
    #     type = "qxl";
    #     ram = 131072;
    #     vram = 131072;
    #     vgamem = 65536;
    #     heads = 1;
    #     primary = true;
    #   };
    # };
    #
    # graphics = {
    #   type = "spice";
    #   autoport = true;
    #   listen = { type = "address"; };
    #   image = { compression = false; };
    # };

    video = {
      model = {
        type = "virtio";
        heads = 1;
        accel3d = true;
        primary = true;
      };
    };

    graphics = {
      type = "spice";
      listen = { type = "none"; };
    };

    sound = {
      model = "ich9";
    };

    audio = {
      id = 1;
      type = "spice";
    };

    redirdev = [
      { bus = "usb"; type = "spicevmc"; }
      { bus = "usb"; type = "spicevmc"; }
    ];

  };

  qemu-commandline = {
    commandline = { xmlns = "http://libvirt.org/schemas/domain/qemu/1.0"; args = []; };
  };
}
