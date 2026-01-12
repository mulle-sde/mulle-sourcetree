# mulle-sourcetree dbstatus

Display the status of the sourcetree database and its components.

## Synopsis

```bash
mulle-sourcetree dbstatus [options]
```

## Description

The `dbstatus` command provides detailed information about the sourcetree database state, including database integrity, performance metrics, and diagnostic information. This helps monitor database health and identify potential issues.

## Options

- `--all` : Show all database status information
- `--integrity` : Check database integrity
- `--performance` : Show performance metrics
- `--size` : Display database size information
- `--locks` : Show current database locks
- `--connections` : Display active connections
- `--verbose` : Show detailed status information

## Examples

### Basic Status
```bash
# Show database status
mulle-sourcetree dbstatus

# Show all status information
mulle-sourcetree dbstatus --all

# Check database integrity
mulle-sourcetree dbstatus --integrity
```

### Performance Monitoring
```bash
# Show performance metrics
mulle-sourcetree dbstatus --performance

# Show database size
mulle-sourcetree dbstatus --size

# Show active connections
mulle-sourcetree dbstatus --connections
```

### Diagnostic Information
```bash
# Show current locks
mulle-sourcetree dbstatus --locks

# Verbose status report
mulle-sourcetree dbstatus --verbose

# Check for issues
mulle-sourcetree dbstatus --diagnose
```

## Status Information

### Database Integrity
- **File integrity**: Checks for database file corruption
- **Index consistency**: Validates database indexes
- **Reference integrity**: Ensures all references are valid
- **Transaction logs**: Checks transaction log integrity

### Performance Metrics
- **Query performance**: Average query execution times
- **Cache hit rates**: Database cache efficiency
- **I/O statistics**: Read/write operation metrics
- **Memory usage**: Database memory consumption

### Size Information
- **Database file size**: Total size of database files
- **Index sizes**: Size of database indexes
- **Log file sizes**: Size of transaction logs
- **Temporary space**: Temporary file usage

### Connection Information
- **Active connections**: Current database connections
- **Connection pool**: Connection pool status
- **Long-running queries**: Queries taking extended time
- **Connection limits**: Connection usage vs limits

## Database Components

### Main Database
- **Node storage**: Node definitions and properties
- **Dependency graph**: Dependency relationships
- **Configuration data**: Configuration settings
- **Metadata**: Database metadata and statistics

### Indexes
- **Node indexes**: Indexes for fast node lookup
- **Property indexes**: Indexes for property queries
- **Dependency indexes**: Indexes for dependency traversal
- **Search indexes**: Full-text search indexes

### Transaction Logs
- **Write-ahead logs**: Transaction durability logs
- **Checkpoint information**: Log checkpoint status
- **Archive logs**: Archived transaction logs
- **Recovery information**: Crash recovery data

## Monitoring Features

### Health Checks
```bash
# Quick health check
mulle-sourcetree dbstatus --health

# Detailed integrity check
mulle-sourcetree dbstatus --integrity --verbose

# Performance check
mulle-sourcetree dbstatus --performance --threshold 100ms
```

### Alert Conditions
- **Corruption detected**: Database file corruption
- **Performance degradation**: Slow query performance
- **Space issues**: Low disk space for database
- **Connection problems**: Connection pool exhaustion

### Threshold Monitoring
```bash
# Set performance thresholds
mulle-sourcetree dbstatus --threshold "query_time:100ms"

# Monitor space usage
mulle-sourcetree dbstatus --threshold "disk_usage:90%"

# Connection monitoring
mulle-sourcetree dbstatus --threshold "connections:80%"
```

## Diagnostic Tools

### Corruption Detection
```bash
# Check for corruption
mulle-sourcetree dbstatus --check-corruption

# Repair corruption
mulle-sourcetree dbstatus --repair-corruption

# Verify repair
mulle-sourcetree dbstatus --verify-repair
```

### Performance Analysis
```bash
# Analyze slow queries
mulle-sourcetree dbstatus --analyze-queries

# Cache performance
mulle-sourcetree dbstatus --cache-stats

# I/O analysis
mulle-sourcetree dbstatus --io-stats
```

### Space Management
```bash
# Analyze space usage
mulle-sourcetree dbstatus --space-analysis

# Identify large objects
mulle-sourcetree dbstatus --large-objects

# Cleanup recommendations
mulle-sourcetree dbstatus --cleanup-suggestions
```

## Maintenance Operations

### Optimization
```bash
# Optimize database
mulle-sourcetree dbstatus --optimize

# Rebuild indexes
mulle-sourcetree dbstatus --rebuild-indexes

# Vacuum database
mulle-sourcetree dbstatus --vacuum
```

### Backup and Recovery
```bash
# Create database backup
mulle-sourcetree dbstatus --backup

# Verify backup integrity
mulle-sourcetree dbstatus --verify-backup

# Recovery testing
mulle-sourcetree dbstatus --test-recovery
```

### Cleanup
```bash
# Clean old logs
mulle-sourcetree dbstatus --clean-logs

# Remove temporary files
mulle-sourcetree dbstatus --clean-temp

# Archive old data
mulle-sourcetree dbstatus --archive
```

## Integration with Other Commands

### With status
```bash
# Overall status including database
mulle-sourcetree status
mulle-sourcetree dbstatus --all
```

### With clean
```bash
# Clean database artifacts
mulle-sourcetree clean --cache
mulle-sourcetree dbstatus --performance
```

### With fix
```bash
# Fix database issues
mulle-sourcetree dbstatus --diagnose
mulle-sourcetree fix --database
```

## Output Formats

### Standard Output
```
Database Status:
  Integrity: OK
  Performance: Good
  Size: 45MB
  Connections: 3/10

Performance Metrics:
  Avg Query Time: 12ms
  Cache Hit Rate: 94%
  I/O Operations: 1,234
```

### JSON Output
```bash
mulle-sourcetree dbstatus --json
```

### Detailed Report
```bash
mulle-sourcetree dbstatus --report > db-report.txt
```

## Common Issues and Solutions

### Performance Issues
```bash
# Slow queries
mulle-sourcetree dbstatus --analyze-queries
mulle-sourcetree dbstatus --optimize

# Low cache hit rate
mulle-sourcetree dbstatus --cache-stats
mulle-sourcetree dbstatus --increase-cache
```

### Space Issues
```bash
# Large database
mulle-sourcetree dbstatus --space-analysis
mulle-sourcetree dbstatus --vacuum

# Log file growth
mulle-sourcetree dbstatus --log-analysis
mulle-sourcetree dbstatus --clean-logs
```

### Connection Issues
```bash
# Connection pool full
mulle-sourcetree dbstatus --connections
mulle-sourcetree dbstatus --increase-pool

# Long-running queries
mulle-sourcetree dbstatus --long-queries
mulle-sourcetree dbstatus --kill-query <query_id>
```

## Notes

- Regular monitoring helps prevent issues
- Some operations may require database downtime
- Backup before major maintenance operations
- Monitor performance trends over time

## See Also

- [`status`](status.md) - Show sourcetree status
- [`clean`](clean.md) - Clean artifacts and caches
- [`fix`](fix.md) - Fix common issues
- [`reset`](reset.md) - Reset sourcetree state