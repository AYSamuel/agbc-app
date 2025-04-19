import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firestore_provider.dart';
import '../models/church_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';

class BranchManagementScreen extends StatelessWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreProvider = Provider.of<FirestoreProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CustomBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Church Branches',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
            ),
            // Branches List
            Expanded(
              child: StreamBuilder<List<ChurchModel>>(
                stream: firestoreProvider.getAllBranches(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final branches = snapshot.data!;
                  
                  if (branches.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.church,
                            size: 64,
                            color: Color(0xFF1A237E),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Branches Found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'There are currently no church branches in the system.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort branches alphabetically by name
                  branches.sort((a, b) => a.name.compareTo(b.name));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppTheme.cardColor,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.church,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            branch.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(branch.location),
                              Text(branch.address),
                              Text('Person in Charge: ${branch.personInCharge}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditBranchDialog(context, branch),
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBranchDialog(BuildContext context, ChurchModel branch) {
    // TODO: Implement branch editing dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Branch'),
        content: const Text('Branch editing dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 