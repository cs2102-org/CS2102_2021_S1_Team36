# pcs
CS2102 Pet Care Center 

## Backend Setup

1) Create `.env` file in `backend` folder
2) In the `.env` file, add `PSQL_USER=your_username`, replace `your_username` with your psql username

### How to run
Before running: 

- `npm install` to install packages
- `psql -f sql_init/init.sql` to create database
- `npm run dev` to run the app




### Deployment to Heroku notes:

#### Database
To initialise:

- Navigate to `init.sql` folder
- Enter `heroku pg:psql --app cs2102-2021-s1-team36 < init.sql` in command line to initiate DB
- Might need to remove `/c pcs` in init.sql

#### Backend
- Require permissions
- WIP

#### Frontend
- Require permissions
- WIP