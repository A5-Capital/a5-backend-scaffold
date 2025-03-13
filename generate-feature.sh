#!/usr/bin/env bash

# Script information
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="A5 Feature Generator"
SCRIPT_DESCRIPTION="A tool to generate feature scaffolding for A5 backend projects"

# Display script banner
echo -e "\n========================================="
echo -e "  ${SCRIPT_NAME} v${SCRIPT_VERSION}"
echo -e "  ${SCRIPT_DESCRIPTION}"
echo -e "=========================================\n"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Function to create a directory if it doesn't exist
create_directory() {
  local dir_path=$1
  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path"
    print_message "$GREEN" "Created directory: $dir_path"
  fi
}

# Function to create a file with content
create_file() {
  local file_path=$1
  local content=$2
  echo -e "$content" > "$file_path"
  print_message "$GREEN" "Created file: $file_path"
}

# Ask for features folder location
print_message "$BLUE" "Enter the path to your features folder (absolute or relative):"
read features_base_path

# Verify if the path exists or can be created
if [ ! -d "$features_base_path" ]; then
  print_message "$YELLOW" "Directory doesn't exist. Do you want to create it? (y/n)"
  read create_dir
  if [[ $create_dir == "y" || $create_dir == "Y" ]]; then
    mkdir -p "$features_base_path"
    if [ $? -ne 0 ]; then
      print_message "$RED" "Failed to create directory. Please check the path and permissions."
      exit 1
    fi
    print_message "$GREEN" "Directory created successfully."
  else
    print_message "$RED" "Exiting as directory doesn't exist."
    exit 1
  fi
fi

# Ask for import style
print_message "$BLUE" "How do you want to make imports? Choose an option:"
print_message "$BLUE" "1. Relative paths (e.g., ../../../features/featureName)"
print_message "$BLUE" "2. Alias (e.g., @/features/featureName)"
read import_style_choice

if [ "$import_style_choice" == "2" ]; then
  print_message "$BLUE" "Enter your alias for the features folder (e.g., @/features):"
  read features_alias
  
  # Remove trailing slash if present
  features_alias=${features_alias%/}
else
  features_alias=""
fi

# Ask for feature name
print_message "$BLUE" "Enter the name of the feature you want to create:"
read feature_name

# Validate feature name
if [ -z "$feature_name" ]; then
  print_message "$RED" "Feature name cannot be empty. Exiting."
  exit 1
fi

# Create feature directory structure
feature_path="$features_base_path/$feature_name"
create_directory "$feature_path"

# Define the structure of a feature
directories=("controllers" "di" "lib" "models" "repository" "routes" "schema" "services" "subscribers" "types")

# Create subdirectories
for dir in "${directories[@]}"; do
  create_directory "$feature_path/$dir"
done

# Function to convert to camelCase
to_camel_case() {
  local str=$1
  # First character to lowercase
  local first_char=$(echo "${str:0:1}" | tr '[:upper:]' '[:lower:]')
  # Rest of the string
  local rest_of_string="${str:1}"
  echo "$first_char$rest_of_string"
}

# Function to convert to PascalCase
to_pascal_case() {
  local str=$1
  # First character to uppercase
  local first_char=$(echo "${str:0:1}" | tr '[:lower:]' '[:upper:]')
  # Rest of the string
  local rest_of_string="${str:1}"
  echo "$first_char$rest_of_string"
}

# Prepare import paths based on choice
if [ "$import_style_choice" == "2" ]; then
  import_path="$features_alias/$feature_name"
else
  # Calculate relative path (simplified for this script)
  import_path="../"
fi

# Convert feature name to different cases
pascal_feature_name=$(to_pascal_case "$feature_name")
camel_feature_name=$(to_camel_case "$feature_name")

# Determine singular name
if [[ "$pascal_feature_name" == *s ]]; then
  singular_name="${pascal_feature_name%s}"
else
  singular_name="$pascal_feature_name"
fi

# Generate controller file
controller_content=$(cat << EOF
import { NextFunction, Request, Response } from 'express';
import { injectable } from 'tsyringe';
import { ServerResponse } from '@/shared/utils/serverResponse';
import { StatusCodes } from 'http-status-codes';
import ${pascal_feature_name}Service from '../services';

@injectable()
export default class ${pascal_feature_name}Controller {
  constructor(private ${camel_feature_name}Service: ${pascal_feature_name}Service) {}
  
  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await this.${camel_feature_name}Service.getAll();
      res.status(StatusCodes.OK).json(ServerResponse.success(result).toJson());
    } catch (error: any) {
      next(error);
    }
  }
}
EOF
)
create_file "$feature_path/controllers/index.ts" "$controller_content"

# Generate DI file
di_content=$(cat << EOF
import { DependencyContainer } from 'tsyringe';
import ${pascal_feature_name}Repository from '../repository';
import ${pascal_feature_name}Service from '../services';
import ${pascal_feature_name}Controller from '../controllers';

export default function register${pascal_feature_name}Dependencies(
  container: DependencyContainer,
) {
  container.registerSingleton(${pascal_feature_name}Repository);
  container.registerSingleton(${pascal_feature_name}Service);
  container.registerSingleton(${pascal_feature_name}Controller);
}
EOF
)
create_file "$feature_path/di/index.ts" "$di_content"

# Generate model file
model_content=$(cat << EOF
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { CustomBaseEntity } from '@/shared/entity/customBaseEntity';
import { I${singular_name}Model } from '$import_path/types';

@Entity({ name: '${feature_name}' })
export default class ${singular_name}Entity extends CustomBaseEntity implements I${singular_name}Model {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 255 })
  name!: string;

  // Add more columns as needed
}
EOF
)
create_file "$feature_path/models/${feature_name}.ts" "$model_content"

# Generate model index file
model_index_content=$(cat << EOF
import ${singular_name}Entity from './${feature_name}';

export { ${singular_name}Entity };

export default {
  ${singular_name}Entity,
};
EOF
)
create_file "$feature_path/models/index.ts" "$model_index_content"

# Generate repository file
repository_content=$(cat << EOF
import { DataSource, Repository } from 'typeorm';
import { inject, singleton } from 'tsyringe';
import { I${pascal_feature_name}Repository } from '../types/repositories';
import ${singular_name}Entity from '../models/${feature_name}';

@singleton()
export default class ${pascal_feature_name}Repository implements I${pascal_feature_name}Repository {
  private repo: Repository<${singular_name}Entity>;

  constructor(@inject('DataSource') private dataSource: DataSource) {
    this.repo = this.dataSource.getRepository(${singular_name}Entity);
  }

  async getAll(): Promise<${singular_name}Entity[]> {
    return this.repo.find();
  }

  async getById(id: string): Promise<${singular_name}Entity | null> {
    return this.repo.findOneBy({ id });
  }

  async create(data: Partial<${singular_name}Entity>): Promise<${singular_name}Entity> {
    const entity = this.repo.create(data);
    return this.repo.save(entity);
  }

  async update(id: string, data: Partial<${singular_name}Entity>): Promise<${singular_name}Entity | null> {
    await this.repo.update(id, data);
    return this.getById(id);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.repo.delete(id);
    return result.affected !== 0;
  }
}
EOF
)
create_file "$feature_path/repository/index.ts" "$repository_content"

# Generate routes file
routes_content=$(cat << EOF
import express from 'express';
import { container } from 'tsyringe';
import ${pascal_feature_name}Controller from '$import_path/controllers';
import AppConfig from '@/infra/api/config';

const ${camel_feature_name}Route = (appConfig: AppConfig): express.Router => {
  const router = express.Router();
  const controller = container.resolve(${pascal_feature_name}Controller);

  router.route('/')
    .get(controller.getAll.bind(controller));

  // Add more routes as needed

  return router;
};

export default ${camel_feature_name}Route;
EOF
)
create_file "$feature_path/routes/index.ts" "$routes_content"

# Generate schema file
schema_content=$(cat << EOF
import { z } from 'zod';
import { stringField } from '@/shared/schema/commonSchema';
import { BaseModelSchema } from '@/shared/schema/globalSchema';
import { IBase } from '@/shared/types';

// Status enum if needed
export const ${singular_name}_STATUS = {
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
} as const;

// Base schema
export const ${singular_name}Schema = BaseModelSchema.extend({
  name: stringField('Name'),
  // Add more fields as needed
});

// Create request schema
export const Create${singular_name}RequestSchema = ${singular_name}Schema.pick({
  name: true,
  // Add more fields as needed
});

// Type definitions
export type T${singular_name}Schema = IBase & z.infer<typeof ${singular_name}Schema>;
export type TCreate${singular_name}RequestSchema = z.infer<typeof Create${singular_name}RequestSchema>;
EOF
)
create_file "$feature_path/schema/index.ts" "$schema_content"

# Generate service file
service_content=$(cat << EOF
import { singleton } from 'tsyringe';
import ${pascal_feature_name}Repository from '../repository';
import ${singular_name}Entity from '../models/${feature_name}';

@singleton()
export default class ${pascal_feature_name}Service {
  constructor(private repository: ${pascal_feature_name}Repository) {}

  async getAll(): Promise<${singular_name}Entity[]> {
    return this.repository.getAll();
  }

  async getById(id: string): Promise<${singular_name}Entity | null> {
    return this.repository.getById(id);
  }

  async create(data: Partial<${singular_name}Entity>): Promise<${singular_name}Entity> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<${singular_name}Entity>): Promise<${singular_name}Entity | null> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<boolean> {
    return this.repository.delete(id);
  }
}
EOF
)
create_file "$feature_path/services/index.ts" "$service_content"

# Generate types file
types_content=$(cat << EOF
import { IBase } from '@/shared/types';

// Status type
export type ${singular_name}Status = 'ACTIVE' | 'INACTIVE';

// Entity interface
export interface I${singular_name}Model extends IBase {
  name: string;
  // Add more properties as needed
}

// DTOs
export type Get${singular_name}ByIdRequest = {
  id: string;
};

export type Create${singular_name}DTO = {
  name: string;
  // Add more properties as needed
};

export type Update${singular_name}DTO = Partial<Create${singular_name}DTO>;
EOF
)
create_file "$feature_path/types/index.ts" "$types_content"

# Generate repository types file
repository_types_content=$(cat << EOF
import ${singular_name}Entity from '$import_path/models/${feature_name}';

export interface I${pascal_feature_name}Repository {
  /**
   * Gets all ${feature_name}
   * @returns Array of ${singular_name} entities
   */
  getAll(): Promise<${singular_name}Entity[]>;

  /**
   * Gets a ${singular_name} by ID
   * @param id The ${singular_name} ID
   * @returns The ${singular_name} entity or null if not found
   */
  getById(id: string): Promise<${singular_name}Entity | null>;

  /**
   * Creates a new ${singular_name}
   * @param data The ${singular_name} data
   * @returns The created ${singular_name} entity
   */
  create(data: Partial<${singular_name}Entity>): Promise<${singular_name}Entity>;

  /**
   * Updates a ${singular_name}
   * @param id The ${singular_name} ID
   * @param data The updated ${singular_name} data
   * @returns The updated ${singular_name} entity or null if not found
   */
  update(id: string, data: Partial<${singular_name}Entity>): Promise<${singular_name}Entity | null>;

  /**
   * Deletes a ${singular_name}
   * @param id The ${singular_name} ID
   * @returns True if deleted, false if not found
   */
  delete(id: string): Promise<boolean>;
}
EOF
)
create_file "$feature_path/types/repositories.ts" "$repository_types_content"

# Create empty files for lib and subscribers
create_file "$feature_path/lib/index.ts" "// Add your utility functions and helpers here"
create_file "$feature_path/subscribers/index.ts" "// Add your event subscribers here"

print_message "$GREEN" "Feature \"$feature_name\" generated successfully!"
print_message "$YELLOW" "Don't forget to:"
print_message "$YELLOW" "1. Register your feature's dependencies in your main DI container"
print_message "$YELLOW" "2. Add your feature's routes to your main Express app"