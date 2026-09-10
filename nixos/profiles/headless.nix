_:
{
  # No console is attached, so a failed stage-2 mount must not park the boot
  # at a sulogin prompt nobody can reach. Without emergency.target the failed
  # unit and whatever requires it stay failed, the rest of the boot proceeds,
  # and sshd comes up for the diagnosis (`systemctl --failed`, `journalctl -b`).
  # The initrd emergency shell (base profile) is separate and stays.
  systemd.enableEmergencyMode = false;
}
