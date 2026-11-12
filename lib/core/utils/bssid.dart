String normalizeBssid(String raw) =>
    raw.trim().toLowerCase().replaceAll('-', ':').split(':').map((octet) => octet.padLeft(2, '0')).join(':');
