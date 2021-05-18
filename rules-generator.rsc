:global zones {"LAN";"WAN";"DMZ";"WIFI";"VPN";"GRE"}
/interface list remove [find builtin=no]
:foreach zone in=$zones do={
    /interface list add name=$zone
}
/ip firewall filter
remove [find dynamic=no]
:foreach zone in=$zones do={
    :local FromZone {"From-". $zone}
    :local ZonetoFirewall {$zone . "-to-Firewall"}
    :local FirewalltoZone {"Firewall-to-" . $zone}
    add action=jump chain=forward disabled=yes in-interface-list=$zone jump-target=$FromZone
    add action=jump chain=input disabled=yes in-interface-list=$zone jump-target=$ZonetoFirewall
    add action=jump chain=output disabled=yes jump-target=$FirewalltoZone out-interface-list=$zone
    add chain=$FromZone action=drop comment="Drop other" disabled=yes
    :local targetzone $zone;
    :foreach zone in=$zones do={
        :local Intrazone {"Intrazone-traffic-" . $zone}
        :if ($targetzone=$zone) do={
            add chain=$FromZone action=jump jump-target=$Intrazone out-interface-list=$zone
            add action=passthrough chain=$Intrazone comment="Intrazone traffic ($zone) - Accept"
            add chain=$Intrazone
            add action=passthrough chain=$ZonetoFirewall comment="$zone to Firewall - Accept"
            add action=accept chain=$ZonetoFirewall comment="$zone-to-Firewall - Accept"
            add action=passthrough chain=$FirewalltoZone comment="Firewall to SZ:$zone - Accept"
            add chain=$FirewalltoZone comment="Accept all"
        } else={
            :local Fromtargetzone {"From-" . $targetzone};
            :local Targetzonetozone {$targetzone . "-to-" . $zone};
            add action=jump chain=$Fromtargetzone jump-target=$Targetzonetozone out-interface-list=$zone;
            add action=passthrough chain=$Targetzonetozone comment="$targetzone to $zone";
            add action=accept chain=$Targetzonetozone comment="$Targetzonetozone";
            }
   }
}
add chain=forward action=drop comment="Drop other" disabled=yes
add chain=input action=drop comment="Drop other" disabled=yes
add chain=output action=drop comment="Drop other" disabled=yes
