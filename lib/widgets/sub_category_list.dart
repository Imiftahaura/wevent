import 'package:flutter/material.dart';

class SubCategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> subCategories;
  final Function(Map<String, dynamic>) onEditSubCategory;
  final Function(int?) onDeleteSubCategory;
  final Function(Map<String, dynamic>) onSubCategoryTap; 

  const SubCategoryList({
    super.key,
    required this.subCategories,
    required this.onEditSubCategory,
    required this.onDeleteSubCategory,
    required this.onSubCategoryTap, 
  });

  @override
  Widget build(BuildContext context) {
    if (subCategories.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subCategories.map((sub) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0), 
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D47A1), 
                    Color(0xFF1976D2), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: InkWell(
                onTap: () {
                  onSubCategoryTap(sub); 
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          sub['nama']!,
                         
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuButton<String>(
                       
                        color: const Color(0xFF0B1A40),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEditSubCategory(sub);
                          } else if (value == 'delete') {
                            onDeleteSubCategory(sub['id'] as int?);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',

                            child: Text('Edit', style: TextStyle(color: Colors.white)),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                           
                            child: Text('Hapus', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                        child: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}