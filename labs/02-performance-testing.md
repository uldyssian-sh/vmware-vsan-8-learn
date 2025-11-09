# Lab 2: vSAN Performance Testing and Optimization

## Objective
Learn how to test, measure, and optimize vSAN performance using various tools and techniques.

## Prerequisites
- Completed [Lab 1: Basic Setup](./01-basic-setup.md)
- vSAN cluster with 4+ hosts
- Test VMs deployed
- Performance monitoring tools

## Lab Environment
- **Cluster**: vSAN-Lab-Cluster
- **Test VMs**: 4 VMs with different storage policies
- **Tools**: VMware vSAN Observer, PowerCLI, OS-level tools

## Exercise 1: Baseline Performance Testing

### Step 1: Deploy Test VMs

```powershell
# Create test VMs with different policies
$testVMs = @(
    @{Name="TestVM-Performance"; Policy="vSAN-Performance"; CPU=4; RAM=8},
    @{Name="TestVM-Balanced"; Policy="vSAN-Balanced"; CPU=2; RAM=4},
    @{Name="TestVM-Capacity"; Policy="vSAN-Capacity"; CPU=2; RAM=4}
)

foreach ($vm in $testVMs) {
    New-VM -Name $vm.Name -Datastore "vsanDatastore" -NumCpu $vm.CPU -MemoryGB $vm.RAM -StoragePolicy (Get-VmStoragePolicy $vm.Policy)
    Write-Host "Created $($vm.Name) with $($vm.Policy) policy"
}
```

### Step 2: Install Performance Testing Tools

On each test VM, install:
- **Linux**: `fio`, `iozone`, `dd`
- **Windows**: `DiskSpd`, `CrystalDiskMark`

#### Linux Installation
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y fio iozone3

# CentOS/RHEL
sudo yum install -y fio iozone
```

### Step 3: Basic I/O Testing

#### Sequential Read/Write Test
```bash
# Sequential write test (4MB blocks)
fio --name=seq-write --rw=write --bs=4M --size=10G --numjobs=1 --runtime=300 --group_reporting

# Sequential read test (4MB blocks)
fio --name=seq-read --rw=read --bs=4M --size=10G --numjobs=1 --runtime=300 --group_reporting
```

#### Random I/O Test
```bash
# Random read test (4K blocks)
fio --name=rand-read --rw=randread --bs=4K --size=10G --numjobs=4 --runtime=300 --group_reporting

# Random write test (4K blocks)
fio --name=rand-write --rw=randwrite --bs=4K --size=10G --numjobs=4 --runtime=300 --group_reporting
```

## Exercise 2: vSAN Performance Monitoring

### Step 1: Enable vSAN Performance Service

```powershell
# Enable performance service
$cluster = Get-Cluster "vSAN-Lab-Cluster"
$spec = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpec
$spec.PerformanceServiceEnabled = $true
Set-VsanClusterConfiguration -Cluster $cluster -VsanClusterConfigSpec $spec
```

### Step 2: Monitor Real-time Performance

```powershell
# Monitor vSAN performance during tests
function Monitor-VsanPerformance {
    param([string]$ClusterName, [int]$DurationMinutes = 10)

    $endTime = (Get-Date).AddMinutes($DurationMinutes)

    while ((Get-Date) -lt $endTime) {
        $stats = Get-Stat -Entity (Get-Cluster $ClusterName) -Stat @(
            "vsan.dom.compmgr.readIops.avg",
            "vsan.dom.compmgr.writeIops.avg",
            "vsan.dom.compmgr.readLatency.avg",
            "vsan.dom.compmgr.writeLatency.avg"
        ) -MaxSamples 1

        foreach ($stat in $stats) {
            Write-Host "$($stat.MetricId): $([math]::Round($stat.Value, 2))"
        }
        Write-Host "---"
        Start-Sleep 30
    }
}

# Start monitoring
Monitor-VsanPerformance -ClusterName "vSAN-Lab-Cluster" -DurationMinutes 15
```

### Step 3: vSAN Observer Setup

1. Download vSAN Observer from VMware
2. Deploy to management network
3. Configure data collection:

```bash
# Start vSAN Observer
java -jar vsanobserver.jar --cluster <CLUSTER_IP> --username <USERNAME> --password <PASSWORD>
```

## Exercise 3: Performance Analysis

### Step 1: Collect Performance Data

```powershell
# Collect comprehensive performance data
$cluster = Get-Cluster "vSAN-Lab-Cluster"
$perfData = @()

# Get datastore performance
$vsanDS = Get-Datastore | Where-Object {$_.Type -eq "vsan"}
$dsStats = Get-Stat -Entity $vsanDS -Stat @(
    "datastore.read.average",
    "datastore.write.average",
    "datastore.totalReadLatency.average",
    "datastore.totalWriteLatency.average"
) -Start (Get-Date).AddHours(-1)

# Get host performance
$hosts = Get-VMHost -Location $cluster
foreach ($host in $hosts) {
    $hostStats = Get-Stat -Entity $host -Stat @(
        "cpu.usage.average",
        "mem.usage.average",
        "net.usage.average"
    ) -Start (Get-Date).AddHours(-1)

    $perfData += @{
        Host = $host.Name
        Stats = $hostStats
    }
}
```

### Step 2: Analyze Cache Performance

```powershell
# Check cache hit ratios
function Get-VsanCacheStats {
    param([string]$ClusterName)

    $cluster = Get-Cluster $ClusterName
    $hosts = Get-VMHost -Location $cluster

    foreach ($host in $hosts) {
        $cacheStats = Get-Stat -Entity $host -Stat @(
            "vsan.dom.compmgr.cacheHitRate.avg",
            "vsan.dom.compmgr.readCacheHitRate.avg",
            "vsan.dom.compmgr.writeCacheHitRate.avg"
        ) -MaxSamples 10

        Write-Host "Host: $($host.Name)"
        foreach ($stat in $cacheStats) {
            Write-Host "  $($stat.MetricId): $([math]::Round($stat.Value, 2))%"
        }
    }
}

Get-VsanCacheStats -ClusterName "vSAN-Lab-Cluster"
```

### Step 3: Network Performance Analysis

```powershell
# Check vSAN network performance
function Test-VsanNetworkPerformance {
    param([string]$ClusterName)

    $cluster = Get-Cluster $ClusterName
    $hosts = Get-VMHost -Location $cluster

    foreach ($host in $hosts) {
        $vsanVmk = Get-VMHostNetworkAdapter -VMHost $host | Where-Object {$_.VsanTrafficEnabled}

        if ($vsanVmk) {
            $netStats = Get-Stat -Entity $host -Stat @(
                "net.usage.average",
                "net.packetsRx.summation",
                "net.packetsTx.summation"
            ) -MaxSamples 5

            Write-Host "Host: $($host.Name) - vSAN Network: $($vsanVmk.IP)"
            foreach ($stat in $netStats) {
                Write-Host "  $($stat.MetricId): $($stat.Value)"
            }
        }
    }
}

Test-VsanNetworkPerformance -ClusterName "vSAN-Lab-Cluster"
```

## Exercise 4: Performance Optimization

### Step 1: Optimize Storage Policies

```powershell
# Create optimized policies based on test results
$optimizedPolicies = @{
    "HighIOPS" = @{
        "VSAN.hostFailuresToTolerate" = "1"
        "VSAN.stripeWidth" = "4"
        "VSAN.cacheReservation" = "50"
        "VSAN.proportionalCapacity" = "25"
    }
    "LowLatency" = @{
        "VSAN.hostFailuresToTolerate" = "1"
        "VSAN.stripeWidth" = "2"
        "VSAN.cacheReservation" = "75"
        "VSAN.proportionalCapacity" = "100"
    }
}

foreach ($policyName in $optimizedPolicies.Keys) {
    New-VmStoragePolicy -Name $policyName -AnyOfRuleSets $optimizedPolicies[$policyName]
    Write-Host "Created optimized policy: $policyName"
}
```

### Step 2: Network Optimization

```powershell
# Configure network optimization
$hosts = Get-VMHost -Location (Get-Cluster "vSAN-Lab-Cluster")

foreach ($host in $hosts) {
    # Enable jumbo frames on vSAN network
    $vsanVmk = Get-VMHostNetworkAdapter -VMHost $host | Where-Object {$_.VsanTrafficEnabled}
    if ($vsanVmk -and $vsanVmk.Mtu -lt 9000) {
        Set-VMHostNetworkAdapter -VirtualNic $vsanVmk -Mtu 9000 -Confirm:$false
        Write-Host "Enabled jumbo frames on $($host.Name)"
    }

    # Optimize TCP/IP stack
    $tcpipStack = Get-VMHostNetworkStack -VMHost $host -Id "vsan"
    if ($tcpipStack) {
        # Configure TCP settings for vSAN
        Write-Host "TCP/IP stack configured for $($host.Name)"
    }
}
```

### Step 3: Storage Optimization

```powershell
# Check and optimize disk group configuration
function Optimize-VsanDiskGroups {
    param([string]$ClusterName)

    $cluster = Get-Cluster $ClusterName
    $hosts = Get-VMHost -Location $cluster

    foreach ($host in $hosts) {
        $diskGroups = Get-VsanDiskGroup -VMHost $host

        Write-Host "Host: $($host.Name)"
        foreach ($dg in $diskGroups) {
            $cacheSize = $dg.CacheDevice.CapacityGB
            $capacitySize = ($dg.CapacityDevice | Measure-Object CapacityGB -Sum).Sum
            $ratio = [math]::Round($capacitySize / $cacheSize, 1)

            Write-Host "  Disk Group: Cache=$($cacheSize)GB, Capacity=$($capacitySize)GB, Ratio=1:$ratio"

            if ($ratio -gt 10) {
                Write-Host "  WARNING: Cache to capacity ratio exceeds 1:10 recommendation" -ForegroundColor Yellow
            }
        }
    }
}

Optimize-VsanDiskGroups -ClusterName "vSAN-Lab-Cluster"
```

## Exercise 5: Performance Validation

### Step 1: Re-run Performance Tests

After optimization, repeat the performance tests from Exercise 1 and compare results.

### Step 2: Create Performance Report

```powershell
# Generate performance comparison report
function New-PerformanceReport {
    param([array]$BeforeData, [array]$AfterData, [string]$OutputPath)

    $report = @{
        TestDate = Get-Date
        Improvements = @()
    }

    # Compare IOPS
    $beforeIOPS = ($BeforeData | Where-Object {$_.Metric -eq "IOPS"}).Value
    $afterIOPS = ($AfterData | Where-Object {$_.Metric -eq "IOPS"}).Value
    $improvement = [math]::Round((($afterIOPS - $beforeIOPS) / $beforeIOPS) * 100, 2)

    $report.Improvements += @{
        Metric = "IOPS"
        Before = $beforeIOPS
        After = $afterIOPS
        ImprovementPercent = $improvement
    }

    $report | ConvertTo-Json -Depth 3 | Out-File $OutputPath
    Write-Host "Performance report saved to $OutputPath"
}
```

### Step 3: Monitor Long-term Performance

```powershell
# Set up continuous monitoring
$monitoringScript = @'
# Schedule this script to run every hour
$cluster = Get-Cluster "vSAN-Lab-Cluster"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$perfData = Get-Stat -Entity $cluster -Stat @(
    "vsan.dom.compmgr.readIops.avg",
    "vsan.dom.compmgr.writeIops.avg"
) -MaxSamples 1

$logEntry = "$timestamp,$($perfData[0].Value),$($perfData[1].Value)"
Add-Content -Path "vsan-performance-log.csv" -Value $logEntry
'@

$monitoringScript | Out-File "Monitor-VsanPerformance.ps1"
```

## Performance Benchmarks

### Expected Performance Ranges

| Configuration | Read IOPS | Write IOPS | Read Latency | Write Latency |
|---------------|-----------|------------|--------------|---------------|
| All-Flash (4 hosts) | 50,000+ | 30,000+ | <2ms | <5ms |
| Hybrid (4 hosts) | 20,000+ | 15,000+ | <5ms | <10ms |
| All-Flash (8 hosts) | 100,000+ | 60,000+ | <2ms | <5ms |

### Optimization Targets

- **Cache Hit Ratio**: >90%
- **Network Utilization**: <70%
- **CPU Usage**: <80%
- **Memory Usage**: <85%

## Troubleshooting Performance Issues

### Common Performance Problems

1. **Low Cache Hit Ratio**
   - Increase cache tier size
   - Optimize workload placement

2. **High Network Latency**
   - Check network configuration
   - Enable jumbo frames
   - Verify network hardware

3. **Storage Bottlenecks**
   - Balance disk groups
   - Optimize storage policies
   - Add more hosts/storage

### Diagnostic Commands

```powershell
# Quick performance health check
function Test-VsanPerformanceHealth {
    $cluster = Get-Cluster "vSAN-Lab-Cluster"

    # Check cache hit ratios
    $cacheHit = Get-Stat -Entity $cluster -Stat "vsan.dom.compmgr.cacheHitRate.avg" -MaxSamples 1
    Write-Host "Cache Hit Ratio: $([math]::Round($cacheHit.Value, 2))%"

    # Check congestion
    $congestion = Get-Stat -Entity $cluster -Stat "vsan.dom.compmgr.congestion.avg" -MaxSamples 1
    Write-Host "Congestion Level: $([math]::Round($congestion.Value, 2))"

    # Check latency
    $latency = Get-Stat -Entity $cluster -Stat "vsan.dom.compmgr.readLatency.avg" -MaxSamples 1
    Write-Host "Average Read Latency: $([math]::Round($latency.Value, 2))ms"
}

Test-VsanPerformanceHealth
```

## Lab Validation

- [ ] Performance baseline established
- [ ] Optimization applied and validated
- [ ] Performance monitoring configured
- [ ] Performance report generated
- [ ] Long-term monitoring setup

## Next Steps

1. Complete [Stretched Cluster Lab](./03-stretched-cluster.md)
2. Explore [Troubleshooting Lab](./04-troubleshooting.md)
3. Advanced [Automation Lab](./05-automation.md)

## Additional Resources

- [vSAN Performance Troubleshooting](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-troubleshooting/GUID-0C7C5C7C-7C7C-7C7C-7C7C-7C7C7C7C7C7C.html)
- [vSAN Observer Guide](https://core.vmware.com/resource/vsan-observer-guide)# Documentation updated Sun Nov  9 14:43:37 CET 2025
