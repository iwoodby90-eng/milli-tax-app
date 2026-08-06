import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import styled from 'styled-components';

const Container = styled.div`
  min-height: 100vh;
  background: #050607;
  color: #fff;
  padding: 24px 20px;
  max-width: 1200px;
  margin: 0 auto;
`;

const Header = styled.div`
  margin-bottom: 32px;
`;

const Title = styled.h1`
  font-family: 'Outfit', sans-serif;
  font-size: 28px;
  font-weight: 700;
  margin: 0 0 4px;
`;

const Subtitle = styled.p`
  color: #8e8e93;
  font-size: 14px;
  margin: 0;
`;

const StatsGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 32px;
`;

const StatCard = styled(motion.div)`
  background: #1c1c1e;
  border-radius: 16px;
  padding: 20px;
  border: 1px solid #2c2c2e;
`;

const StatLabel = styled.div`
  font-size: 12px;
  color: #8e8e93;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
`;

const StatValue = styled.div`
  font-family: 'Outfit', sans-serif;
  font-size: 24px;
  font-weight: 700;
`;

const StatChange = styled.div`
  font-size: 12px;
  margin-top: 4px;
  color: ${props => props.positive ? '#34c759' : '#ff3b30'};
`;

const Section = styled.div`
  margin-bottom: 32px;
`;

const SectionTitle = styled.h2`
  font-family: 'Outfit', sans-serif;
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 16px;
`;

const Table = styled.div`
  background: #1c1c1e;
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid #2c2c2e;
`;

const TableRow = styled.div`
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr 1fr;
  padding: 14px 20px;
  border-bottom: 1px solid #2c2c2e;
  align-items: center;
  font-size: 14px;

  &:last-child { border-bottom: none; }
  &:hover { background: #2c2c2e; }
`;

const TableHeader = styled(TableRow)`
  font-weight: 600;
  color: #8e8e93;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  background: #1a1a1c;
`;

const Badge = styled.span`
  padding: 4px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  background: ${props => {
    if (props.active) return 'rgba(52, 199, 89, 0.15)';
    if (props.trial) return 'rgba(255, 204, 0, 0.15)';
    if (props.cancelled) return 'rgba(255, 59, 48, 0.15)';
    return 'rgba(142, 142, 147, 0.15)';
  }};
  color: ${props => {
    if (props.active) return '#34c759';
    if (props.trial) return '#ffcc00';
    if (props.cancelled) return '#ff3b30';
    return '#8e8e93';
  }};
`;

const ChartContainer = styled.div`
  background: #1c1c1e;
  border-radius: 16px;
  padding: 24px;
  border: 1px solid #2c2c2e;
  margin-bottom: 32px;
`;

const Bar = styled.div`
  height: 8px;
  border-radius: 4px;
  background: ${props => props.color || '#ffcc00'};
  width: ${props => props.width}%;
  margin-top: 6px;
  transition: width 0.5s ease;
`;

const BarRow = styled.div`
  margin-bottom: 16px;
`;

const BarLabel = styled.div`
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  margin-bottom: 4px;
`;

const TabBar = styled.div`
  display: flex;
  gap: 8px;
  margin-bottom: 24px;
  border-bottom: 1px solid #2c2c2e;
  padding-bottom: 12px;
`;

const Tab = styled.button`
  background: none;
  border: none;
  color: ${props => props.active ? '#ffcc00' : '#8e8e93'};
  font-size: 14px;
  font-weight: 600;
  padding: 8px 16px;
  cursor: pointer;
  border-bottom: 2px solid ${props => props.active ? '#ffcc00' : 'transparent'};
  transition: all 0.2s;
`;

const AdminDashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeSubscriptions: 0,
    trialUsers: 0,
    mrr: 0,
    totalRevenue: 0,
    churnRate: 0,
  });
  const [users, setUsers] = useState([]);
  const [planDistribution, setPlanDistribution] = useState({ basic: 0, pro: 0, elite: 0 });

  useEffect(() => {
    // Load from localStorage for demo; in production, fetch from admin API
    const stored = localStorage.getItem('milli_admin_stats');
    if (stored) {
      setStats(JSON.parse(stored));
    } else {
      // Demo data
      const demoStats = {
        totalUsers: 1247,
        activeSubscriptions: 893,
        trialUsers: 187,
        mrr: 24847,
        totalRevenue: 87420,
        churnRate: 3.2,
      };
      setStats(demoStats);
      localStorage.setItem('milli_admin_stats', JSON.stringify(demoStats));
    }

    const storedUsers = localStorage.getItem('milli_admin_users');
    if (storedUsers) {
      setUsers(JSON.parse(storedUsers));
    } else {
      const demoUsers = [
        { id: 1, name: 'Alexander Chen', email: 'alex@example.com', plan: 'Elite', status: 'active', joined: '2026-08-01' },
        { id: 2, name: 'Sarah Johnson', email: 'sarah@example.com', plan: 'Pro', status: 'active', joined: '2026-08-02' },
        { id: 3, name: 'Mike Torres', email: 'mike@example.com', plan: 'Basic', status: 'trial', joined: '2026-08-03' },
        { id: 4, name: 'Emma Wilson', email: 'emma@example.com', plan: 'Pro', status: 'active', joined: '2026-08-03' },
        { id: 5, name: 'James Park', email: 'james@example.com', plan: 'Elite', status: 'cancelled', joined: '2026-07-28' },
      ];
      setUsers(demoUsers);
      localStorage.setItem('milli_admin_users', JSON.stringify(demoUsers));
    }

    setPlanDistribution({ basic: 45, pro: 38, elite: 17 });
  }, []);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(amount);
  };

  return (
    <Container>
      <Header>
        <Title>Admin Dashboard</Title>
        <Subtitle>Milli Tax Vault platform overview and user management</Subtitle>
      </Header>

      <TabBar>
        <Tab active={activeTab === 'overview'} onClick={() => setActiveTab('overview')}>Overview</Tab>
        <Tab active={activeTab === 'users'} onClick={() => setActiveTab('users')}>Users</Tab>
        <Tab active={activeTab === 'revenue'} onClick={() => setActiveTab('revenue')}>Revenue</Tab>
      </TabBar>

      {activeTab === 'overview' && (
        <>
          <StatsGrid>
            <StatCard initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
              <StatLabel>Total Users</StatLabel>
              <StatValue>{stats.totalUsers.toLocaleString()}</StatValue>
              <StatChange positive>+12.4% this month</StatChange>
            </StatCard>
            <StatCard initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }}>
              <StatLabel>Active Subscriptions</StatLabel>
              <StatValue>{stats.activeSubscriptions.toLocaleString()}</StatValue>
              <StatChange positive>+8.1% this month</StatChange>
            </StatCard>
            <StatCard initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}>
              <StatLabel>Trial Users</StatLabel>
              <StatValue>{stats.trialUsers.toLocaleString()}</StatValue>
              <StatChange positive>+24.3% this week</StatChange>
            </StatCard>
            <StatCard initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }}>
              <StatLabel>Monthly Recurring Revenue</StatLabel>
              <StatValue>{formatCurrency(stats.mrr)}</StatValue>
              <StatChange positive>+15.7% MoM</StatChange>
            </StatCard>
            <StatCard initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}>
              <StatLabel>Total Revenue</StatLabel>
              <StatValue>{formatCurrency(stats.totalRevenue)}</StatValue>
              <StatChange positive>+22.1% YoY</StatChange>
            </StatCard>
            <StatCard initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.25 }}>
              <StatLabel>Churn Rate</StatLabel>
              <StatValue>{stats.churnRate}%</StatValue>
              <StatChange positive={false}>-0.8% MoM</StatChange>
            </StatCard>
          </StatsGrid>

          <ChartContainer>
            <SectionTitle>Plan Distribution</SectionTitle>
            <BarRow>
              <BarLabel>
                <span>Basic (Free)</span>
                <span>{planDistribution.basic}%</span>
              </BarLabel>
              <Bar width={planDistribution.basic} color="#8e8e93" />
            </BarRow>
            <BarRow>
              <BarLabel>
                <span>Pro ($29.99/mo)</span>
                <span>{planDistribution.pro}%</span>
              </BarLabel>
              <Bar width={planDistribution.pro} color="#ffcc00" />
            </BarRow>
            <BarRow>
              <BarLabel>
                <span>Elite ($49.99/mo)</span>
                <span>{planDistribution.elite}%</span>
              </BarLabel>
              <Bar width={planDistribution.elite} color="#ff9500" />
            </BarRow>
          </ChartContainer>
        </>
      )}

      {activeTab === 'users' && (
        <Section>
          <SectionTitle>User Management</SectionTitle>
          <Table>
            <TableHeader>
              <div>Name</div>
              <div>Email</div>
              <div>Plan</div>
              <div>Status</div>
              <div>Joined</div>
            </TableHeader>
            {users.map(user => (
              <TableRow key={user.id}>
                <div>{user.name}</div>
                <div style={{ color: '#8e8e93' }}>{user.email}</div>
                <div>{user.plan}</div>
                <div>
                  <Badge active={user.status === 'active'} trial={user.status === 'trial'} cancelled={user.status === 'cancelled'}>
                    {user.status}
                  </Badge>
                </div>
                <div style={{ color: '#8e8e93' }}>{user.joined}</div>
              </TableRow>
            ))}
          </Table>
        </Section>
      )}

      {activeTab === 'revenue' && (
        <>
          <StatsGrid>
            <StatCard>
              <StatLabel>MRR</StatLabel>
              <StatValue>{formatCurrency(stats.mrr)}</StatValue>
            </StatCard>
            <StatCard>
              <StatLabel>ARR (Projected)</StatLabel>
              <StatValue>{formatCurrency(stats.mrr * 12)}</StatValue>
            </StatCard>
            <StatCard>
              <StatLabel>ARPU</StatLabel>
              <StatValue>{formatCurrency(stats.mrr / stats.activeSubscriptions)}</StatValue>
            </StatCard>
            <StatCard>
              <StatLabel>LTV (Est.)</StatLabel>
              <StatValue>{formatCurrency((stats.mrr / stats.activeSubscriptions) * (100 / stats.churnRate))}</StatValue>
            </StatCard>
          </StatsGrid>

          <ChartContainer>
            <SectionTitle>Revenue by Plan</SectionTitle>
            <BarRow>
              <BarLabel>
                <span>Pro ($29.99/mo) - {Math.round(stats.activeSubscriptions * 0.38)} users</span>
                <span>{formatCurrency(Math.round(stats.activeSubscriptions * 0.38 * 29.99))}/mo</span>
              </BarLabel>
              <Bar width={68} color="#ffcc00" />
            </BarRow>
            <BarRow>
              <BarLabel>
                <span>Elite ($49.99/mo) - {Math.round(stats.activeSubscriptions * 0.17)} users</span>
                <span>{formatCurrency(Math.round(stats.activeSubscriptions * 0.17 * 49.99))}/mo</span>
              </BarLabel>
              <Bar width={32} color="#ff9500" />
            </BarRow>
          </ChartContainer>
        </>
      )}
    </Container>
  );
};

export default AdminDashboard;