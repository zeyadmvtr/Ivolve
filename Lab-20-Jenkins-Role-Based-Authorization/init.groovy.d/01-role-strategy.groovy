import jenkins.model.*
import hudson.security.*
import com.michelin.cio.hudson.plugins.rolestrategy.*
import java.lang.reflect.Field

println("--> Starting Automated Role-Based Authorization Configuration...")

def instance = Jenkins.getInstance()

// 1. Configure Local User Database Security Realm
def realm = new HudsonPrivateSecurityRealm(false)
realm.createAccount("user1", "user1Pass2026!")
realm.createAccount("user2", "user2Pass2026!")
realm.createAccount("admin", "adminRoot2026!")
instance.setSecurityRealm(realm)
println("--> Accounts 'user1', 'user2', and 'admin' created successfully.")

// 2. Configure Role-Based Authorization Strategy
Set<Permission> adminPermissions = new HashSet<Permission>()
adminPermissions.add(Jenkins.ADMINISTER)

Set<Permission> readOnlyPermissions = new HashSet<Permission>()
readOnlyPermissions.add(Jenkins.READ)
readOnlyPermissions.add(Item.READ)
readOnlyPermissions.add(View.READ)

Role adminRole = new Role("admin", adminPermissions)
Role readOnlyRole = new Role("read-only", readOnlyPermissions)

RoleMap globalRoleMap = new RoleMap()
globalRoleMap.addRole(adminRole)
globalRoleMap.addRole(readOnlyRole)

// Assign users to roles
globalRoleMap.assignRole(adminRole, "user1")
globalRoleMap.assignRole(adminRole, "admin")
globalRoleMap.assignRole(readOnlyRole, "user2")

Map<String, RoleMap> grantedRoles = new HashMap<String, RoleMap>()
grantedRoles.put(RoleBasedAuthorizationStrategy.GLOBAL, globalRoleMap)

RoleBasedAuthorizationStrategy strategy = new RoleBasedAuthorizationStrategy(grantedRoles)
instance.setAuthorizationStrategy(strategy)
instance.save()

println("--> [SUCCESS] Role-based Strategy active: user1 -> admin, user2 -> read-only.")
