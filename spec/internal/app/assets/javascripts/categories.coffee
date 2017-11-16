LiveRecord.Model.create(
  {
    modelName: 'Category',
    hasMany: {
      posts: { foreignKey: 'category_id', modelName: 'Post' }
    },
    plugins: {
      LiveDOM: true
    },
    classMethods: {
    },
    instanceMethods: {
    }
  }
)
